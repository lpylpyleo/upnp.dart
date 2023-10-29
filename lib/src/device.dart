part of '../upnp.dart';

/// A upnp device
class Device {
  /// The xml element the properties of this object were initialized from
  late XmlElement deviceElement;

  /// The urn of this type of device
  String? deviceType;

  /// The base url of this device
  String? urlBase;

  /// The user friendly name
  String? friendlyName;

  /// The manufacturer of this device
  String? manufacturer;

  /// The name of this model
  String? modelName;

  /// The universal device name of this device
  String? udn;

  /// The uuid extracted from the [udn]
  String? uuid;

  /// The url provided in [loadFromXml]
  String? url;

  /// The url for presentation
  String? presentationUrl;

  /// The type of model of this device
  String? modelType;

  /// The long user-friendly title
  String? modelDescription;

  /// The model numbe rof this device
  String? modelNumber;

  /// The URL to the manufacturer site
  String? manufacturerUrl;

  /// The list of icons
  List<Icon> icons = [];

  /// The list of provided services
  List<ServiceDescription> services = [];

  /// Returns all IDs/service names of the services of this device.
  /// See [ServiceDescription.id]
  List<String?> get serviceNames => services.map((x) => x.id).toList();

  /// Initializes all fields from the xml element
  void loadFromXml(String? url, XmlElement element) {
    this.url = url;
    deviceElement = element;

    final uri = Uri.parse(url!);

    urlBase = XmlUtils.getTextSafe(deviceElement, 'URLBase');

    urlBase ??= uri.toString();

    if (deviceElement.findElements('device').isEmpty) {
      throw Exception('ERROR: Invalid Device XML!\n\n$deviceElement');
    }

    final deviceNode = XmlUtils.getElementByName(deviceElement, 'device');

    deviceType = XmlUtils.getTextSafe(deviceNode, 'deviceType');
    friendlyName = XmlUtils.getTextSafe(deviceNode, 'friendlyName');
    modelName = XmlUtils.getTextSafe(deviceNode, 'modelName');
    manufacturer = XmlUtils.getTextSafe(deviceNode, 'manufacturer');
    udn = XmlUtils.getTextSafe(deviceNode, 'UDN');
    presentationUrl = XmlUtils.getTextSafe(deviceNode, 'presentationURL');
    modelType = XmlUtils.getTextSafe(deviceNode, 'modelType');
    modelDescription = XmlUtils.getTextSafe(deviceNode, 'modelDescription');
    manufacturerUrl = XmlUtils.getTextSafe(deviceNode, 'manufacturerURL');

    if (udn != null) {
      uuid = udn!.substring('uuid:'.length);
    }

    if (deviceNode.findElements('iconList').isNotEmpty) {
      final iconList = deviceNode.findElements('iconList').first;
      for (var child in iconList.children) {
        if (child is XmlElement) {
          final icon = Icon();
          icon.mimetype = XmlUtils.getTextSafe(child, 'mimetype');
          final width = XmlUtils.getTextSafe(child, 'width');
          final height = XmlUtils.getTextSafe(child, 'height');
          final depth = XmlUtils.getTextSafe(child, 'depth');
          final url = XmlUtils.getTextSafe(child, 'url');
          if (width != null) {
            icon.width = int.parse(width);
          }

          if (height != null) {
            icon.height = int.parse(height);
          }

          if (depth != null) {
            icon.depth = int.parse(depth);
          }

          icon.url = url;

          icons.add(icon);
        }
      }
    }

    final Uri baseUri = Uri.parse(urlBase!);

    void processDeviceNode(XmlElement e) {
      if (e.findElements('serviceList').isNotEmpty) {
        final list = e.findElements('serviceList').first;
        for (var svc in list.children) {
          if (svc is XmlElement) {
            services.add(ServiceDescription.fromXml(baseUri, svc));
          }
        }
      }

      if (e.findElements('deviceList').isNotEmpty) {
        final list = e.findElements('deviceList').first;
        for (var dvc in list.children) {
          if (dvc is XmlElement) {
            processDeviceNode(dvc);
          }
        }
      }
    }

    processDeviceNode(deviceNode);
  }

  /// Returns the service of the specified type or null if this device does not support this service
  Future<Service?> getService(String type) async {
    try {
      final service = services.firstWhere(
        (it) => it.type == type || it.id == type,
      );
      return await service.getService(this);
    } catch (e) {
      return null;
    }
  }
}

/// An icon of an upnp device
class Icon {
  /// The mimetype of this icon, always "image/<format>" like "image/png"
  String? mimetype;

  /// The amount of horizontal pixels
  int? width;

  /// The amount of vertical pixels
  int? height;

  /// The color depth of this image
  int? depth;

  /// The url to this icon
  String? url;
}

/// This class holds some constants for URNs for common devices
class CommonDevices {
  /// The urn for DIAL devices
  static const String dial = 'urn:dial-multiscreen-org:service:dial:1';

  /// The urn for chromecasts, which is currently [dial]
  static const String chromecast = dial;

  /// The urn for WEMO devices
  static const String wemo = 'urn:Belkin:device:controllee:1';

  /// The urn for wifi router devices
  static const String wifiRouter =
      'urn:schemas-wifialliance-org:device:WFADevice:1';

  /// The urn for wan router devices
  static const String wanRouter =
      'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1';
}
