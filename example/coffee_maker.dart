import 'package:upnp2/upnp.dart';

void main() {
  final discover = DeviceDiscoverer();

  discover.getDevices(type: CommonDevices.WEMO).then((devices) {
    return devices.where((it) => it.modelName == 'CoffeeMaker');
  }).then((devices) {
    for (var device in devices) {
      Service? service;
      device.getService('urn:Belkin:service:deviceevent:1').then((_) {
        service = _;
        return service!.invokeAction('GetAttributes', {});
      }).then((result) {
        final attributes = WemoHelper.parseAttributes(result['attributeList']!);
        final brewing = attributes['Brewing'];
        final brewed = attributes['Brewed'];
        final mode = attributes['Mode'];
        print('Mode: $mode');
        print('Brewing: $brewing');
        print('Brewed: $brewed');
      });
    }
  });
}
