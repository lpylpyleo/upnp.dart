part of '../upnp.dart';

class StateSubscriptionManager {
  HttpServer? server;
  final Map<String, StateSubscription> _subs = {};

  Future<void> init() async {
    await close();

    server = await HttpServer.bind('0.0.0.0', 0);

    server!.listen((HttpRequest request) {
      final String id = request.uri.path.substring(1);

      if (_subs.containsKey(id)) {
        _subs[id]!.deliver(request);
      } else if (request.uri.path == '/_list') {
        request.response
          ..writeln(_subs.keys.join('\n'))
          ..close();
      } else if (request.uri.path == '/_state') {
        var out = '';
        for (String sid in _subs.keys) {
          out += '$sid: ${_subs[sid]!._lastValue}\n';
        }
        request.response
          ..write(out)
          ..close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.close();
      }
    }, onError: (e) {});
  }

  Future<void> close() async {
    for (String key in _subs.keys.toList()) {
      _subs[key]!._done();
      _subs.remove(key);
    }

    if (server != null) {
      await server!.close(force: true);
      server = null;
    }
  }

  Stream<dynamic> subscribeToVariable(StateVariable v) {
    final id = v.getGenericId();
    StateSubscription? sub;
    if (_subs.containsKey(id)) {
      sub = _subs[id];
    } else {
      sub = _subs[id] = StateSubscription();
      sub.eventUrl = v.service.eventSubUrl;
      sub.lastStateVariable = v;
      sub.manager = this;
      sub.init();
    }

    return sub!._controller!.stream;
  }

  Stream<dynamic> subscribeToService(Service service) {
    final id = sha256.convert(utf8.encode(service.eventSubUrl!)).toString();
    StateSubscription? sub = _subs[id];
    if (sub == null) {
      sub = _subs[id] = StateSubscription();
      sub.eventUrl = service.eventSubUrl;
      sub.manager = this;
      sub.init();
    }
    return sub._controller!.stream;
  }
}

class InternalNetworkUtils {
  static Future<String> getMostLikelyHost(Uri uri) async {
    final parts = uri.host.split('.');
    final interfaces = await NetworkInterface.list();

    String? calc(int skip) {
      final prefix = '${parts.take(parts.length - skip).join('.')}.';

      for (NetworkInterface interface in interfaces) {
        for (InternetAddress addr in interface.addresses) {
          if (addr.address.startsWith(prefix)) {
            return addr.address;
          }
        }
      }

      return null;
    }

    for (var i = 1; i <= 3; i++) {
      final ip = calc(i);
      if (ip != null) {
        return ip;
      }
    }

    return Platform.localHostname;
  }
}

class StateSubscription {
  static int refresh = 30;

  late StateSubscriptionManager manager;
  StateVariable? lastStateVariable;
  String? eventUrl;
  StreamController<dynamic>? _controller;
  Timer? _timer;
  String? lastCallbackUrl;

  String? _lastSid;

  dynamic _lastValue;

  void init() {
    _controller = StreamController<dynamic>.broadcast(
        onListen: () async {
          try {
            await _sub();
          } catch (e, stack) {
            _controller!.addError(e, stack);
          }
        },
        onCancel: () => _unsub());
  }

  Future<void> deliver(HttpRequest request) async {
    final content =
        utf8.decode(await request.fold(<int>[], (List<int> a, List<int> b) {
      return a..addAll(b);
    }));
    await request.response.close();

    final doc = XmlDocument.parse(content);
    final props = doc.rootElement.children.whereType<XmlElement>().toList();
    final map = <String, dynamic>{};
    for (XmlElement prop in props) {
      if (prop.children.isEmpty) {
        continue;
      }

      final XmlElement child =
          prop.children.firstWhere((x) => x is XmlElement) as XmlElement;
      final String p = child.name.local;

      if (lastStateVariable != null && lastStateVariable!.name == p) {
        final value = XmlUtils.asRichValue(child.innerText);
        _controller!.add(value);
        _lastValue = value;
        return;
      } else if (lastStateVariable == null) {
        map[p] = XmlUtils.asRichValue(child.innerText);
      }
    }

    if (lastStateVariable == null && map.isNotEmpty) {
      _controller!.add(map);
      _lastValue = map;
    }
  }

  String _getId() {
    if (lastStateVariable != null) {
      return lastStateVariable!.getGenericId();
    } else {
      return sha256.convert(utf8.encode(eventUrl!)).toString();
    }
  }

  Future _sub() async {
    final id = _getId();

    final uri = Uri.parse(eventUrl!);

    final request = await UpnpCommon.httpClient.openUrl('SUBSCRIBE', uri);

    final url = await _getCallbackUrl(uri, id);
    lastCallbackUrl = url;

    request.headers.set('User-Agent', 'UPNP.dart/1.0');
    request.headers.set('ACCEPT', '*/*');
    request.headers.set('CALLBACK', '<$url>');
    request.headers.set('NT', 'upnp:event');
    request.headers.set('TIMEOUT', 'Second-$refresh');
    request.headers.set('HOST', '${request.uri.host}:${request.uri.port}');

    final response = await request.close();
    await response.drain();

    if (response.statusCode != HttpStatus.ok) {
      throw Exception('Failed to subscribe.');
    }

    _lastSid = response.headers.value('SID');

    _timer = Timer(Duration(seconds: refresh), () {
      _timer = null;
      _refresh();
    });
  }

  Future _refresh() async {
    final uri = Uri.parse(eventUrl!);

    final id = _getId();
    final url = await _getCallbackUrl(uri, id);
    if (url != lastCallbackUrl) {
      await _unsub().timeout(const Duration(seconds: 10));
      await _sub();
      return;
    }

    final request = await UpnpCommon.httpClient.openUrl('SUBSCRIBE', uri);

    request.headers.set('User-Agent', 'UPNP.dart/1.0');
    request.headers.set('ACCEPT', '*/*');
    request.headers.set('TIMEOUT', 'Second-$refresh');
    request.headers.set('SID', _lastSid!);
    request.headers.set('HOST', '${request.uri.host}:${request.uri.port}');

    HttpClientResponse response;
    try {
      response = await request.close().timeout(
            const Duration(seconds: 10),
          );
    } on TimeoutException {
      return;
    }

    if (response.statusCode != HttpStatus.ok) {
      await _controller!.close();
      return;
    } else {
      _timer = Timer(Duration(seconds: refresh), () {
        _timer = null;
        _refresh();
      });
    }
  }

  Future<String> _getCallbackUrl(Uri uri, String id) async {
    final host = await InternalNetworkUtils.getMostLikelyHost(uri);
    return 'http://$host:${manager.server!.port}/$id';
  }

  Future _unsub() async {
    final request = await UpnpCommon.httpClient
        .openUrl('UNSUBSCRIBE', Uri.parse(eventUrl!));

    request.headers.set('User-Agent', 'UPNP.dart/1.0');
    request.headers.set('ACCEPT', '*/*');
    request.headers.set('SID', _lastSid!);

    final response = await request.close().timeout(const Duration(seconds: 10));

    await response.drain();

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _done() {
    _timer?.cancel();
    _timer = null;

    _controller?.close();
  }
}
