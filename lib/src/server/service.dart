part of '../../server.dart';

class UpnpHostService {
  final String? type;
  final String? id;
  final String? simpleName;

  List<UpnpHostAction> actions = <UpnpHostAction>[];

  UpnpHostService({this.type, this.id, this.simpleName});

  XmlDocument toXml() {
    final x = XmlBuilder();
    x.processing('xml', 'version="1.0"'); // 添加 XML 声明
    x.element('scpd', nest: () {
      x.namespace('urn:schemas-upnp-org:service-1-0');
      x.element('specVersion', nest: () {
        x.element('major', nest: '1');
        x.element('minor', nest: '0');
      });

      x.element('actionList', nest: () {
        for (var action in actions) {
          action.applyToXml(x);
        }
      });
    });
    return x.buildDocument();
  }
}
