import 'package:test/test.dart';
import 'package:upnp2/upnp.dart';
import 'package:xml/xml.dart';

void main() {
  test('service parse', () {
    const content = '''<root xmlns="urn:schemas-upnp-org:device-1-0">
    <specVersion>
        <major>1</major>
        <minor>0</minor>
    </specVersion>
    <device>
        <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
        <presentationURL>/</presentationURL>
        <friendlyName>T14 EXTREME</friendlyName>
        <manufacturer>lucky</manufacturer>
        <manufacturerURL>http://www.xxxxx.com</manufacturerURL>
        <modelDescription>GX Media Renderer</modelDescription>
        <modelName>HappyLucky</modelName>
        <modelURL>http://www.xxxxx.com</modelURL>
        <dlna:X_DLNADOC xmlns:dlna="urn:schemas-dlna-org:device-1-0">DMR-1.50</dlna:X_DLNADOC>
        <UDN>uuid:A252BA22-9245-2D32-A189-BA2292922D39</UDN>
        <UID>-7056134368720033613</UID>
        <serviceList>
            <service>
                <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
                <SCPDURL>/dlna-vir/dmr/AVTransport_scpd.xml</SCPDURL>
                <controlURL>_urn:schemas-upnp-org:service:AVTransport_control</controlURL>
                <eventSubURL>_urn:schemas-upnp-org:service:AVTransport_event</eventSubURL>
            </service>
            <service>
                <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
                <SCPDURL>/dlna-vir/dmr/ConnectionManager_scpd.xml</SCPDURL>
                <controlURL>_urn:schemas-upnp-org:service:ConnectionManager_control</controlURL>
                <eventSubURL>_urn:schemas-upnp-org:service:ConnectionManager_event</eventSubURL>
            </service>
            <service>
                <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
                <SCPDURL>/dlna-vir/dmr/RenderingControl_scpd.xml</SCPDURL>
                <controlURL>_urn:schemas-upnp-org:service:RenderingControl_control</controlURL>
                <eventSubURL>_urn:schemas-upnp-org:service:RenderingControl_event</eventSubURL>
            </service>
        </serviceList>
    </device>
    <URLBase>http://192.168.1.2:49152/</URLBase>
</root>''';
    final doc = XmlDocument.parse(content);
    final device = Device()
      ..loadFromXml(
          'http://http://192.168.1.2:49152/rootDesc.xml', doc.rootElement);
    expect(device.services.length, 3);
    expect(device.services[0].controlUrl,
        'http://192.168.1.2:49152/_urn:schemas-upnp-org:service:AVTransport_control');
    expect(device.services[0].eventSubUrl,
        'http://192.168.1.2:49152/_urn:schemas-upnp-org:service:AVTransport_event');
    expect(device.services[0].scpdUrl,
        'http://192.168.1.2:49152/dlna-vir/dmr/AVTransport_scpd.xml');
  });
}
