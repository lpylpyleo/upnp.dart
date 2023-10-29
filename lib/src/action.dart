part of '../upnp.dart';

class Action {
  late Service service;
  String? name;
  List<ActionArgument> arguments = [];

  Action();

  Action.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, 'name');

    void addArgDef(XmlElement argdef, [bool stripPrefix = false]) {
      var name = XmlUtils.getTextSafe(argdef, 'name');

      if (name == null) {
        return;
      }

      final direction = XmlUtils.getTextSafe(argdef, 'direction');
      final relatedStateVariable =
          XmlUtils.getTextSafe(argdef, 'relatedStateVariable');
      var isRetVal = direction == 'out';

      if (this.name!.startsWith('Get')) {
        final of = this.name!.substring(3);
        if (of == name) {
          isRetVal = true;
        }
      }

      if (name.startsWith('Get') && stripPrefix) {
        name = name.substring(3);
      }

      arguments.add(ActionArgument(
          this, name, direction, relatedStateVariable, isRetVal));
    }

    final argumentLists = e.findElements('argumentList');
    if (argumentLists.isNotEmpty) {
      final argList = argumentLists.first;
      if (argList.children
          .any((x) => x is XmlElement && x.name.local == 'name')) {
        // Bad UPnP Implementation fix for WeMo
        addArgDef(argList, true);
      } else {
        for (var argdef in argList.children.whereType<XmlElement>()) {
          addArgDef(argdef);
        }
      }
    }
  }

  Future<Map<String, String>> invoke(Map<String, dynamic> args) async {
    final param =
        '  <u:$name xmlns:u="${service.type}">${args.keys.map((argumentName) {
      String argument = args[argumentName].toString();
      argument = argument.replaceAll('&', '&amp;');
      argument = argument.replaceAll('<', '&lt;');
      argument = argument.replaceAll('>', '&gt;');
      argument = argument.replaceAll('\'', '&apos;');
      argument = argument.replaceAll('"', '&quot;');

      return '<$argumentName>$argument</$argumentName>';
    }).join('\n')}</u:$name>\n';

    final result = await service.sendToControlUrl(name, param);
    final doc = XmlDocument.parse(result);
    XmlElement response = doc.rootElement;

    if (response.name.local != 'Body') {
      response =
          response.children.firstWhere((x) => x is XmlElement) as XmlElement;
    }

    if (const bool.fromEnvironment('upnp.action.show_response',
        defaultValue: false)) {
      print('Got Action Response: ${response.toXmlString()}');
    }

    if (!response.name.local.contains('Response') &&
        response.children.length > 1) {
      response = response.children[1] as XmlElement;
    }

    if (response.children.length == 1) {
      final d = response.children[0];

      if (d is XmlElement) {
        if (d.name.local.contains('Response')) {
          response = d;
        }
      }
    }

    if (const bool.fromEnvironment('upnp.action.show_response',
        defaultValue: false)) {
      print('Got Action Response (Real): ${response.toXmlString()}');
    }

    final List<XmlElement> results =
        response.children.whereType<XmlElement>().toList();
    final map = <String, String>{};
    for (XmlElement r in results) {
      map[r.name.local] = r.innerText;
    }
    return map;
  }
}

class StateVariable {
  late Service service;
  String? name;
  String? dataType;
  dynamic defaultValue;
  bool doesSendEvents = false;

  StateVariable();

  StateVariable.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, 'name');
    dataType = XmlUtils.getTextSafe(e, 'dataType');
    defaultValue =
        XmlUtils.asValueType(XmlUtils.getTextSafe(e, 'defaultValue'), dataType);
    doesSendEvents = e.getAttribute('sendEvents') == 'yes';
  }

  String getGenericId() {
    return sha1
        .convert(utf8.encode('${service.device!.uuid}::${service.id}::$name'))
        .toString();
  }
}

class ActionArgument {
  final Action action;
  final String? name;
  final String? direction;
  final String? relatedStateVariable;
  final bool isRetVal;

  ActionArgument(this.action, this.name, this.direction,
      this.relatedStateVariable, this.isRetVal);

  StateVariable? getStateVariable() {
    if (relatedStateVariable != null) {
      return null;
    }

    final Iterable<StateVariable> vars = action.service.stateVariables
        .where((x) => x.name == relatedStateVariable);

    if (vars.isNotEmpty) {
      return vars.first;
    }

    return null;
  }
}
