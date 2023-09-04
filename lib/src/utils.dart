library upnp.utils;

import 'dart:io';

import 'package:xml/xml.dart';

/// An exception thrown during an upnp action
class UpnpException implements Exception {
  /// The xml element which caused this exception
  final XmlElement element;

  /// Initializes this exception with the specified element
  UpnpException(this.element);

  @override
  String toString() => 'UpnpException: ${element.toXmlString()}';
}

// TODO maybe replace some methods with extensions?
/// A helper class for XML documents
class XmlUtils {
  /// Returns the first element by name from the specified node
  static XmlElement getElementByName(XmlElement node, String name) {
    return node.findElements(name).first;
  }

  /// Returns the first String property with this name or null
  static String? getTextSafe(XmlElement node, String name) {
    final elements = node.findElements(name);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.innerText;
  }

  /// Replaces escaped angle brackets (<>) to their real chars
  static String unescape(String input) {
    return input.replaceAll('&gt;', '>').replaceAll('&lt;', '<');
  }

  /// Tries to parse booleans and numbers from a string
  static dynamic asRichValue(String value) {
    if (value.toLowerCase() == 'true') {
      return true;
    }

    if (value.toLowerCase() == 'false') {
      return false;
    }

    if (value.toLowerCase() == 'null') {
      return null;
    }

    final number = num.tryParse(value);

    if (number != null) {
      return number;
    }

    return value;
  }

  /// Returns the value of input parsed as either string or number,
  /// depending on the given type
  static dynamic asValueType(input, String? type) {
    if (input == null) {
      return null;
    }

    if (type is String) {
      type = type.toLowerCase();
    }

    if (type == 'string') {
      return input.toString();
    } else if (type == 'number' ||
        type == 'integer' ||
        type == 'int' ||
        type == 'double' ||
        type == 'float') {
      return num.tryParse(input.toString());
    } else {
      return input.toString();
    }
  }
}

class UpnpCommon {
  static HttpClient httpClient = HttpClient();
}
