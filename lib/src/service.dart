part of '../upnp.dart';

const String _soapBody = '''
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
  {param}
  </s:Body>
</s:Envelope>
''';

/// A description for an upnp service
class ServiceDescription {
  /// The urn of this services type
  String? type;

  /// The urn of this services id
  String? id;

  /// The url to control this service
  String? controlUrl;

  /// The url to subscribe to events
  String? eventSubUrl;

  /// The url this services description
  String? scpdUrl;

  /// Initializes this description from the provided xml element
  ServiceDescription.fromXml(Uri uriBase, XmlElement service) {
    type = XmlUtils.getTextSafe(service, 'serviceType')!.trim();
    id = XmlUtils.getTextSafe(service, 'serviceId')!.trim();
    controlUrl =
        patchUrl(uriBase, XmlUtils.getTextSafe(service, 'controlURL')!.trim())
            .toString();
    eventSubUrl =
        patchUrl(uriBase, XmlUtils.getTextSafe(service, 'eventSubURL')!.trim())
            .toString();

    final m = XmlUtils.getTextSafe(service, 'SCPDURL');

    if (m != null) {
      scpdUrl = uriBase.resolve(m).toString();
    }
  }

  /// [Uri.resolve] will check legality and throw `FormatException`
  /// These `controlURL` and `eventSubURL` are start with `_`.
  /// [patchUrl] fixed as with these, see more in `test/parse_test.dart`.
  static Uri patchUrl(Uri uri, String path) {
    if (path.startsWith('_')) {
      return uri.replace(path: path);
    }
    return uri.resolve(path);
  }

  /// Returns the according service from this description.
  /// The provided device gets used to initialize it in the service
  Future<Service?> getService([Device? device]) async {
    if (scpdUrl == null) {
      throw Exception('Unable to fetch service, no SCPD URL.');
    }

    HttpClientRequest request;
    try {
      request = await UpnpCommon.httpClient
          .getUrl(Uri.parse(scpdUrl!))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return Future.value(null);
    }

    final response = await request.close();

    if (response.statusCode != 200) {
      return null;
    }

    XmlElement doc;

    try {
      var content =
          await response.cast<List<int>>().transform(utf8.decoder).join();
      content = content.replaceAll('\u00EF\u00BB\u00BF', '');
      doc = XmlDocument.parse(content).rootElement;
    } catch (e) {
      return null;
    }

    final actionList = doc.findElements('actionList');
    final varList = doc.findElements('serviceStateTable');
    final acts = <Action>[];

    if (actionList.isNotEmpty) {
      for (var e in actionList.first.children) {
        if (e is XmlElement) {
          acts.add(Action.fromXml(e));
        }
      }
    }

    final vars = <StateVariable>[];

    if (varList.isNotEmpty) {
      for (var e in varList.first.children) {
        if (e is XmlElement) {
          vars.add(StateVariable.fromXml(e));
        }
      }
    }

    final service =
        Service(device, type, id, controlUrl, eventSubUrl, scpdUrl, acts, vars);

    for (var act in acts) {
      act.service = service;
    }

    for (var v in vars) {
      v.service = service;
    }

    return service;
  }

  @override
  String toString() => 'ServiceDescription($id)';
}

/// A upnp service
class Service {
  /// The device this service is running on
  final Device? device;

  /// The type of this service
  final String? type;

  /// The id of this service
  final String? id;

  /// The actions which can be invoked
  final List<Action> actions;

  /// The state variables of this service
  final List<StateVariable> stateVariables;

  /// The url to invoke this service
  String? controlUrl;

  /// The url to subscribe to events
  String? eventSubUrl;

  /// The url to the service description
  String? scpdUrl;

  Service(this.device, this.type, this.id, this.controlUrl, this.eventSubUrl,
      this.scpdUrl, this.actions, this.stateVariables);

  /// Returns a list of the names of the actions
  /// See [Action.name]
  List<String?> get actionNames => actions.map((x) => x.name).toList();

  /// Sends a request to the control url with the name of the action
  /// and the param. Used by [Action.invoke(args)]
  Future<String> sendToControlUrl(String? name, String param) async {
    final body = _soapBody.replaceAll('{param}', param);

    if (const bool.fromEnvironment('upnp.debug.control', defaultValue: false)) {
      print('Send to $controlUrl (SOAPACTION: $type#$name): $body');
    }

    final request = await UpnpCommon.httpClient.postUrl(Uri.parse(controlUrl!));
    request.headers.set('SOAPACTION', '"$type#$name"');
    request.headers.set('Content-Type', 'text/xml; charset="utf-8"');
    request.headers.set('User-Agent', 'CyberGarage-HTTP/1.0');
    // We use UTF-8 in the body so we use it here to calculate the length
    request.headers.set('Content-Length', utf8.encode(body).length);
    request.write(body);
    final response = await request.close();

    final content =
        await response.cast<List<int>>().transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      try {
        final doc = XmlDocument.parse(content);
        throw UpnpException(doc.rootElement);
      } catch (e) {
        if (e is! UpnpException) {
          throw Exception('\n\n$content');
        } else {
          rethrow;
        }
      }
    } else {
      return content;
    }
  }

  /// Invoke an action with the specified name and args
  Future<Map<String, String>> invokeAction(
      String name, Map<String, dynamic> args) async {
    return await actions.firstWhere((it) => it.name == name).invoke(args);
  }
}
