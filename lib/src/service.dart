part of upnp;

const String _soapBody = '''
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
  {param}
  </s:Body>
</s:Envelope>
''';

class ServiceDescription {
  String? type;
  String? id;
  String? controlUrl;
  String? eventSubUrl;
  String? scpdUrl;

  ServiceDescription.fromXml(Uri uriBase, XmlElement service) {
    type = XmlUtils.getTextSafe(service, 'serviceType')!.trim();
    id = XmlUtils.getTextSafe(service, 'serviceId')!.trim();
    controlUrl = uriBase
        .resolve(XmlUtils.getTextSafe(service, 'controlURL')!.trim())
        .toString();
    eventSubUrl = uriBase
        .resolve(XmlUtils.getTextSafe(service, 'eventSubURL')!.trim())
        .toString();

    final m = XmlUtils.getTextSafe(service, 'SCPDURL');

    if (m != null) {
      scpdUrl = uriBase.resolve(m).toString();
    }
  }

  Future<Service?> getService([Device? device]) async {
    if (scpdUrl == null) {
      throw Exception('Unable to fetch service, no SCPD URL.');
    }

    final request = await UpnpCommon.httpClient
        .getUrl(Uri.parse(scpdUrl!))
        .timeout(const Duration(seconds: 5),
            onTimeout: (() => null) as FutureOr<HttpClientRequest> Function()?);

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

class Service {
  final Device? device;
  final String? type;
  final String? id;
  final List<Action> actions;
  final List<StateVariable> stateVariables;

  String? controlUrl;
  String? eventSubUrl;
  String? scpdUrl;

  Service(this.device, this.type, this.id, this.controlUrl, this.eventSubUrl,
      this.scpdUrl, this.actions, this.stateVariables);

  List<String?> get actionNames => actions.map((x) => x.name).toList();

  Future<String> sendToControlUrl(String? name, String param) async {
    final body = _soapBody.replaceAll('{param}', param);

    if (const bool.fromEnvironment('upnp.debug.control', defaultValue: false)) {
      print('Send to $controlUrl (SOAPACTION: $type#$name): $body');
    }

    final request = await UpnpCommon.httpClient.postUrl(Uri.parse(controlUrl!));
    request.headers.set('SOAPACTION', '"$type#$name"');
    request.headers.set('Content-Type', 'text/xml; charset="utf-8"');
    request.headers.set('User-Agent', 'CyberGarage-HTTP/1.0');
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

  Future<Map<String, String>> invokeAction(
      String name, Map<String, dynamic> args) async {
    return await actions.firstWhere((it) => it.name == name).invoke(args);
  }
}
