part of '../upnp.dart';

// TODO maybe move to utils.dart?
/// A helper class for WEMO devices.
/// Apparently WEMO devices use a lot of escaped angle brackets in their attributes
class WemoHelper {
  /// Parses attributes from the input xml string
  static Map<String, dynamic> parseAttributes(String input) {
    final doc = XmlDocument.parse(
            '<attributes>${XmlUtils.unescape(input)}</attributes>')
        .rootElement;
    final attr = {};
    doc.children.whereType<XmlElement>().forEach((element) {
      final name = element.findElements('name').first.innerText.trim();
      dynamic value = element.findElements('value').first.innerText.trim();
      value = num.tryParse(value as String) ?? value;

      value = (value == 'true' || value == 'false') ? value == 'true' : value;

      attr[name] = value;
    });
    return attr as Map<String, dynamic>;
  }

  /// Encodes attributes from a map to an XML String
  static String encodeAttributes(Map<String, dynamic> attr) {
    final buff = StringBuffer();
    for (var key in attr.keys) {
      buff.write('<attribute><name>$key</name>'
          '<value>${attr[key]}</value></attribute>');
    }
    return buff.toString().replaceAll('>', '&gt;').replaceAll('<', '&lt;');
  }
}
