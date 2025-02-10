part of '../../server.dart';

typedef HostActionHandler = Future<Map<String, String>> Function(Map<String, String> inputs);

class UpnpHostAction {
  final String name;
  final List<UpnpHostActionArgument> inputs;
  final List<UpnpHostActionArgument> outputs;
  final HostActionHandler? handler;

  UpnpHostAction(this.name, {this.inputs = const [], this.outputs = const [], this.handler});

  void applyToXml(XmlBuilder x) {
    x.element('action', nest: () {
      x.element('name', nest: name);
      x.element('argumentList', nest: () {
        // 填充输入参数
        for (var input in inputs) {
          input.applyToXml(x);
        }
        // 填充输出参数
        for (var output in outputs) {
          output.applyToXml(x);
        }
      });
    });
  }
}

class UpnpHostActionArgument {
  final String name;
  final bool isOutput;
  final String? relatedStateVariable;

  UpnpHostActionArgument(this.name, this.isOutput, {this.relatedStateVariable});

  void applyToXml(XmlBuilder x) {
    x.element('argument', nest: () {
      x.element('name', nest: name);
      x.element('direction', nest: isOutput ? 'out' : 'in');
      if (relatedStateVariable != null) {
        x.element('relatedStateVariable', nest: relatedStateVariable);
      }
    });
  }
}
