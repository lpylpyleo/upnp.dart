part of upnp.server;

class UpnpServer {
  static final ContentType _xmlType =
      ContentType.parse('text/xml; charset="utf-8"');

  final UpnpHostDevice device;

  UpnpServer(this.device);

  Future handleRequest(HttpRequest request) async {
    final Uri uri = request.uri;
    final String path = uri.path;

    if (path == '/upnp/root.xml') {
      await handleRootRequest(request);
    } else if (path.startsWith('/upnp/services/') && path.endsWith('.xml')) {
      await handleServiceRequest(request);
    } else if (path.startsWith('/upnp/control/') && request.method == 'POST') {
      await handleControlRequest(request);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  Future handleRootRequest(HttpRequest request) async {
    final urlBase = request.requestedUri.resolve('/').toString();
    final xml = device.toRootXml(urlBase: urlBase);
    request.response
      ..headers.contentType = _xmlType
      ..writeln(xml);
    await request.response.close();
  }

  Future handleServiceRequest(HttpRequest request) async {
    var name = request.uri.pathSegments.last;
    if (name.endsWith('.xml')) {
      name = name.substring(0, name.length - 4);
    }
    var service = device.findService(name);

    service ??= device.findService(Uri.decodeComponent(name));

    if (service == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } else {
      final xml = service.toXml();
      request.response
        ..headers.contentType = _xmlType
        ..writeln(xml);
      await request.response.close();
    }
  }

  Future handleControlRequest(HttpRequest request) async {
    final bytes =
        await request.fold(<int>[], (List<int> a, List<int> b) => a..addAll(b));
    final xml = XmlDocument.parse(utf8.decode(bytes));
    final root = xml.rootElement;
    final body = root.firstChild;
    var service = device.findService(request.uri.pathSegments.last);

    service ??=
        device.findService(Uri.decodeComponent(request.uri.pathSegments.last));

    if (service == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    for (XmlNode node in body!.children) {
      if (node is XmlElement) {
        final name = node.name.local;
        UpnpHostAction act;
        try {
          act = service.actions.firstWhere((x) => x.name == name);
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        if (act.handler != null) {
          // TODO(kaendfinger): make this have inputs and outputs.
          await act.handler!({});
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }
      }
    }
  }
}
