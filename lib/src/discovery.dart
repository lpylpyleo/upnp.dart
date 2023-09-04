part of upnp;

final InternetAddress _v4Multicast = InternetAddress('239.255.255.250');
final InternetAddress _v6Multicast = InternetAddress('FF05::C');

class DeviceDiscoverer {
  final List<RawDatagramSocket> _sockets = <RawDatagramSocket>[];
  StreamController<DiscoveredClient> _clientController =
      StreamController.broadcast();

  late List<NetworkInterface> _interfaces;

  static void _doNowt(Exception e) {}

  /// defaults to port 1900 to be able to receive broadcast notifications
  /// and not just M-SEARCH replies.
  Future start({
    bool ipv4 = true,
    bool ipv6 = true,
    Function(Exception) onError = _doNowt,
    int port = 1900,
  }) async {
    _interfaces = await NetworkInterface.list();

    if (ipv4) {
      await _createSocket(InternetAddress.anyIPv4, port, onError: onError);
    }

    if (ipv6) {
      await _createSocket(InternetAddress.anyIPv6, port, onError: onError);
    }
  }

  Future<void> _createSocket(
    InternetAddress address,
    int port, {
    Function(Exception) onError = _doNowt,
  }) async {
    final socket = await RawDatagramSocket.bind(
      address,
      port,
      reuseAddress: true,
      // Windows and Android do not support reusePort
      reusePort: !Platform.isWindows && !Platform.isAndroid,
    );

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;
    socket.multicastHops = 50;

    socket.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
          final packet = socket.receive();
          socket.writeEventsEnabled = true;
          socket.readEventsEnabled = true;

          if (packet == null) {
            return;
          }

          final data = utf8.decode(packet.data);
          final parts = data.split('\r\n');
          parts.removeWhere((x) => x.trim().isEmpty);
          final firstLine = parts.removeAt(0);

          if ((firstLine.toLowerCase().trim() ==
                  'HTTP/1.1 200 OK'.toLowerCase()) ||
              (firstLine.toLowerCase().trim() ==
                  'NOTIFY * HTTP/1.1'.toLowerCase())) {
            final headers = <String, String>{};
            final client = DiscoveredClient();

            for (var part in parts) {
              final hp = part.split(':');
              final name = hp[0].trim();
              final value = (hp..removeAt(0)).join(':').trim();
              headers[name.toUpperCase()] = value;
            }

            if (!headers.containsKey('LOCATION')) {
              return;
            }

            client.st = headers['ST'];
            client.usn = headers['USN'];
            client.location = headers['LOCATION'];
            client.server = headers['SERVER'];
            client.headers = headers;

            _clientController.add(client);
          }

          break;
        default:
          // We do not care about any other packages
          break;
      }
    });

    for (var interface in _interfaces) {
      if (address.type == InternetAddressType.IPv4) {
        try {
          socket.joinMulticast(_v4Multicast, interface);
        } on Exception catch (e) {
          onError(Exception('proto: IPv4, IF: ${interface.name}, $e'));
        }
      }

      if (address.type == InternetAddressType.IPv6) {
        try {
          socket.joinMulticast(_v6Multicast, interface);
        } on Exception catch (e) {
          onError(Exception('proto: IPv6, IF: ${interface.name}, $e'));
        }
      }
    }

    _sockets.add(socket);
  }

  void stop() {
    if (_discoverySearchTimer != null) {
      _discoverySearchTimer!.cancel();
      _discoverySearchTimer = null;
    }

    for (var socket in _sockets) {
      socket.close();
    }

    if (!_clientController.isClosed) {
      _clientController.close();
      _clientController = StreamController<DiscoveredClient>.broadcast();
    }
  }

  Stream<DiscoveredClient> get clients => _clientController.stream;

  void search([String? searchTarget]) {
    searchTarget ??= 'upnp:rootdevice';

    final buff = StringBuffer();

    buff.write('M-SEARCH * HTTP/1.1\r\n');
    buff.write('HOST: 239.255.255.250:1900\r\n');
    buff.write('MAN: "ssdp:discover"\r\n');
    buff.write('MX: 1\r\n');
    buff.write('ST: $searchTarget\r\n');
    buff.write('USER-AGENT: unix/5.1 UPnP/1.1 crash/1.0\r\n\r\n');
    final data = utf8.encode(buff.toString());

    for (var socket in _sockets) {
      if (socket.address.type == _v4Multicast.type) {
        socket.send(data, _v4Multicast, 1900);
      }

      if (socket.address.type == _v6Multicast.type) {
        socket.send(data, _v6Multicast, 1900);
      }
    }
  }

  Future<List<DiscoveredClient>> discoverClients(
      {Duration timeout = const Duration(seconds: 5)}) async {
    final list = <DiscoveredClient>[];

    final sub = clients.listen((client) => list.add(client));

    if (_sockets.isEmpty) {
      await start(port: 0);
    }

    search();
    await Future.delayed(timeout);
    await sub.cancel();
    stop();
    return list;
  }

  Timer? _discoverySearchTimer;

  Stream<DiscoveredClient> quickDiscoverClients(
      {Duration? timeout = const Duration(seconds: 5),
      Duration? searchInterval = const Duration(seconds: 10),
      String? query,
      bool unique = true}) async* {
    if (_sockets.isEmpty) {
      await start(port: 0);
    }

    final seen = <String?>{};

    if (timeout != null) {
      search(query);
      Future.delayed(timeout, () {
        stop();
      });
    } else if (searchInterval != null) {
      search(query);
      _discoverySearchTimer = Timer.periodic(searchInterval, (_) {
        search(query);
      });
    }

    await for (var client in clients) {
      if (unique && seen.contains(client.usn)) {
        continue;
      }

      seen.add(client.usn);
      yield client;
    }
  }

  Future<List<DiscoveredDevice>> discoverDevices(
      {String? type, Duration timeout = const Duration(seconds: 5)}) {
    return discoverClients(timeout: timeout).then((clients) {
      if (clients.isEmpty) {
        return [];
      }

      final uuids = clients
          .where((client) => client.usn != null)
          .map((client) => client.usn!.split('::').first)
          .toSet();
      final devices = <DiscoveredDevice>[];

      for (var uuid in uuids) {
        final deviceClients = clients.where((client) {
          return client.usn != null && client.usn!.split('::').first == uuid;
        }).toList();
        final location = deviceClients.first.location;
        final serviceTypes = deviceClients.map((it) => it.st).toSet().toList();
        final device = DiscoveredDevice();
        device.serviceTypes = serviceTypes;
        device.uuid = uuid;
        device.location = location;
        if (type == null || serviceTypes.contains(type)) {
          devices.add(device);
        }
      }

      for (var client in clients.where((it) => it.usn == null)) {
        final device = DiscoveredDevice();
        device.serviceTypes = [client.st];
        device.uuid = null;
        device.location = client.location;
        if (type == null || device.serviceTypes.contains(type)) {
          devices.add(device);
        }
      }

      return devices;
    });
  }

  Future<List<Device>> getDevices(
      {String? type,
      Duration timeout = const Duration(seconds: 5),
      bool silent = true}) async {
    final results = await discoverDevices(type: type, timeout: timeout);

    final list = <Device>[];
    for (var result in results) {
      try {
        final device = await result.getRealDevice();

        if (device == null) {
          continue;
        }
        list.add(device);
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }

    return list;
  }
}

class DiscoveredDevice {
  List<String?> serviceTypes = [];
  String? uuid;
  String? location;

  Future<Device?> getRealDevice() async {
    HttpClientResponse response;

    try {
      final request = await UpnpCommon.httpClient
          .getUrl(Uri.parse(location!))
          .timeout(const Duration(seconds: 5));

      response = await request.close();
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('ERROR: Failed to fetch device description.'
          ' Status Code: ${response.statusCode}');
    }

    XmlDocument doc;

    try {
      final content =
          await response.cast<List<int>>().transform(utf8.decoder).join();
      doc = XmlDocument.parse(content);
    } on Exception catch (e) {
      throw FormatException('ERROR: Failed to parse'
          ' device description. $e');
    }

    if (doc.findAllElements('device').isEmpty) {
      throw ArgumentError('Not SCPD Compatible');
    }

    return Device()..loadFromXml(location, doc.rootElement);
  }
}

class DiscoveredClient {
  String? st;
  String? usn;
  String? server;
  String? location;
  Map<String, String>? headers;

  DiscoveredClient();

  DiscoveredClient.fake(String loc) {
    location = loc;
  }

  @override
  String toString() {
    final buff = StringBuffer();
    buff.writeln('ST: $st');
    buff.writeln('USN: $usn');
    buff.writeln('SERVER: $server');
    buff.writeln('LOCATION: $location');
    return buff.toString();
  }

  Future<Device?> getDevice() async {
    Uri uri;

    try {
      uri = Uri.parse(location!);
    } catch (e) {
      return null;
    }

    final request = await UpnpCommon.httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));

    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('ERROR: Failed to fetch device description.'
          ' Status Code: ${response.statusCode}');
    }

    XmlDocument doc;

    try {
      final content =
          await response.cast<List<int>>().transform(utf8.decoder).join();
      doc = XmlDocument.parse(content);
    } on Exception catch (e) {
      throw FormatException('ERROR: Failed to parse device'
          ' description. $e');
    }

    return Device()..loadFromXml(location, doc.rootElement);
  }
}
