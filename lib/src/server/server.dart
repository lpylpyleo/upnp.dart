part of '../../server.dart';

class UpnpServer {
  static final ContentType _xmlType = ContentType.parse('text/xml; charset="utf-8"');

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
    final bytes = await request.fold(<int>[], (List<int> a, List<int> b) => a..addAll(b));
    final xml = XmlDocument.parse(utf8.decode(bytes));
    final root = xml.rootElement;
    final body = root.firstChild;
    var service = device.findService(request.uri.pathSegments.last);

    service ??= device.findService(Uri.decodeComponent(request.uri.pathSegments.last));

    if (service == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    for (XmlNode node in body!.children) {
      if (node is XmlElement) {
        final name = node.name.local;
        UpnpHostAction? act;
        try {
          act = service.actions.firstWhere((x) => x.name == name);
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          print('Error handling control request $name: $e');
          return;
        }

        if (act.handler != null) {
          // 解析输入参数
          final inputs = <String, String>{};
          for (var arg in node.children) {
            if (arg is XmlElement) {
              inputs[arg.name.local] = arg.innerText;
            }
          }

          // 执行处理函数并获取输出
          final outputs = await act.handler!(inputs);

          // 构建SOAP响应
          final responseXml = '''
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:${name}Response xmlns:u="${service.type}">
${outputs.entries.map((e) => '      <${e.key}>${_xmlEscape(e.value)}</${e.key}>').join('\n')}
    </u:${name}Response>
  </s:Body>
</s:Envelope>''';

          request.response
            ..headers.contentType = _xmlType
            ..write(responseXml);
          await request.response.close();
          return;
        }
      }
    }

    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
  }

  // 辅助函数：转义XML特殊字符
  String _xmlEscape(dynamic text) {
    return text.toString().replaceAllMapped(
          RegExp('[&<>"\']'),
          (match) => switch (match[0]) {
            '&' => '&amp;',
            '<' => '&lt;',
            '>' => '&gt;',
            '"' => '&quot;',
            "'" => '&apos;',
            _ => match[0]!,
          },
        );
  }
}
