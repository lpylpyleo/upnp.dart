part of '../../server.dart';

class UpnpHostDevice {
  final String? deviceType;
  final String? friendlyName;
  final String? manufacturer;
  final String? manufacturerUrl;
  final String? modelName;
  final String? modelDescription;
  final String? modelNumber;
  final String? modelUrl;
  final String? udn;
  final String? serialNumber;
  final String? presentationUrl;
  final String? upc;

  final List<UpnpHostIcon> icons;
  final List<UpnpHostService> services;

  UpnpHostDevice({
    required this.services,
    this.icons = const [],
    this.deviceType,
    this.friendlyName,
    this.manufacturer,
    this.manufacturerUrl,
    this.modelName,
    this.modelNumber,
    this.modelDescription,
    this.modelUrl,
    this.serialNumber,
    this.presentationUrl,
    this.udn,
    this.upc,
  });

  UpnpHostService? findService(String? name) {
    try {
      return services.firstWhere((service) => service.simpleName == name || service.id == name);
    } catch (e) {
      return null;
    }
  }

  XmlNode toRootXml({String? urlBase}) {
    final x = XmlBuilder();
    x.element('root', nest: () {
      x.namespace('urn:schemas-upnp-org:device-1-0');
      x.element('specVersion', nest: () {
        x.element('major', nest: '1');
        x.element('minor', nest: '0');
      });

      if (urlBase != null) {
        x.element('URLBase', nest: urlBase);
      }

      x.element('device', nest: () {
        if (deviceType != null) {
          x.element('deviceType', nest: deviceType);
        }

        if (friendlyName != null) {
          x.element('friendlyName', nest: friendlyName);
        }

        if (manufacturer != null) {
          x.element('manufacturer', nest: manufacturer);
        }

        if (manufacturerUrl != null) {
          x.element('manufacturerURL', nest: manufacturerUrl);
        }

        if (modelName != null) {
          x.element('modelName', nest: modelName);
        }

        if (modelDescription != null) {
          x.element('modelDescription', nest: modelDescription);
        }

        if (modelNumber != null) {
          x.element('modelNumber', nest: modelNumber);
        }

        if (modelUrl != null) {
          x.element('modelURL', nest: modelUrl);
        }

        if (serialNumber != null) {
          x.element('serialNumber', nest: serialNumber);
        }

        if (udn != null) {
          x.element('UDN', nest: udn);
        }

        if (presentationUrl != null) {
          x.element('presentationURL', nest: presentationUrl);
        }

        if (icons.isNotEmpty) {
          x.element('iconList', nest: () {
            for (UpnpHostIcon icon in icons) {
              icon.applyToXml(x);
            }
          });
        }

        x.element('serviceList', nest: () {
          for (var service in services) {
            x.element('service', nest: () {
              final svcName = service.simpleName ?? Uri.encodeComponent(service.id!);
              x.element('serviceType', nest: service.type);
              x.element('serviceId', nest: service.id);
              x.element('controlURL', nest: '/upnp/control/$svcName');
              x.element('eventSubURL', nest: '/upnp/events/$svcName');
              x.element('SCPDURL', nest: '/upnp/services/$svcName.xml');
            });
          }
        });
      });
    });
    return x.buildDocument();
  }
}

class UpnpHostIcon {
  final String? mimetype;
  final int? width;
  final int? height;
  final int? depth;
  final String? url;

  UpnpHostIcon({this.mimetype, this.width, this.height, this.depth, this.url});

  void applyToXml(XmlBuilder builder) {
    builder.element('icon', nest: () {
      if (mimetype != null) {
        builder.element('mimetype', nest: mimetype);
      }

      if (width != null) {
        builder.element('width', nest: width.toString());
      }

      if (height != null) {
        builder.element('height', nest: height.toString());
      }

      if (depth != null) {
        builder.element('depth', nest: depth.toString());
      }

      if (url != null) {
        builder.element('url', nest: url.toString());
      }
    });
  }
}
