import 'package:test/test.dart';
import 'package:upnp2/upnp.dart';
import 'package:xml/xml.dart';

void main() {
  test('url patch', () {
    final o = Uri.parse('http://a.com/path');
    expect(o.resolve('a:b'), Uri.parse('a:b'));
    expect(() => o.resolve('_a:b'), throwsA(isA<FormatException>()));

    final uri = Uri.parse('http://a.com/path');
    final n1 = ServiceDescription.patchUrl(uri, '/foo?a');
    expect(n1.path, '/foo');
    expect(n1.query, 'a');
    
    final n2 = ServiceDescription.patchUrl(uri, 'foo');
    expect(n2.path, '/foo');
    expect(n2.query, '');

    expect(
        ServiceDescription.patchUrl(uri, 'foo'), Uri.parse('http://a.com/foo'));
    expect(ServiceDescription.patchUrl(uri, '/foo'),
        Uri.parse('http://a.com/foo'));
    expect(ServiceDescription.patchUrl(uri, '/foo?a'),
        Uri.parse('http://a.com/foo?a'));
    expect(ServiceDescription.patchUrl(uri, '_foo:a'),
        Uri.parse('http://a.com/_foo:a'));
  });

  test('service parse', () {
    // https://github.com/daniel-naegele/upnp.dart/issues/11
    const content1 = '''<root xmlns="urn:schemas-upnp-org:device-1-0">
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

    final d1 = Device()
      ..loadFromXml('http://192.168.1.2:49152/rootDesc.xml',
          XmlDocument.parse(content1).rootElement);
    expect(d1.services.length, 3);
    expect(d1.services[0].controlUrl,
        'http://192.168.1.2:49152/_urn:schemas-upnp-org:service:AVTransport_control');
    expect(d1.services[0].eventSubUrl,
        'http://192.168.1.2:49152/_urn:schemas-upnp-org:service:AVTransport_event');
    expect(d1.services[0].scpdUrl,
        'http://192.168.1.2:49152/dlna-vir/dmr/AVTransport_scpd.xml');

    const content2 = '''<root xmlns="urn:schemas-upnp-org:device-1-0">
    <specVersion>
        <major>1</major>
        <minor>0</minor>
    </specVersion>
    <device>
        <deviceType>urn:schemas-wifialliance-org:device:WFADevice:1</deviceType>
        <friendlyName>WFADevice</friendlyName>
        <manufacturer>Broadcom Corporation</manufacturer>
        <manufacturerURL>http://www.broadcom.com</manufacturerURL>
        <modelDescription>Wireless Device</modelDescription>
        <modelName>WPS</modelName>
        <modelNumber>X1</modelNumber>
        <serialNumber>0000001</serialNumber>
        <UDN>uuid:650431eb-4b92-0383-0de7-584be9a45c74</UDN>
        <serviceList>
            <service>
                <serviceType>urn:schemas-wifialliance-org:service:WFAWLANConfig:1</serviceType>
                <serviceId>urn:wifialliance-org:serviceId:WFAWLANConfig1</serviceId>
                <SCPDURL>/x_wfawlanconfig.xml</SCPDURL>
                <controlURL>/control?WFAWLANConfig</controlURL>
                <eventSubURL>/event?WFAWLANConfig</eventSubURL>
            </service>
        </serviceList>
    </device>
</root>''';

    final d2 = Device()
      ..loadFromXml('http://192.168.1.2:49152/rootDesc.xml',
          XmlDocument.parse(content2).rootElement);
    expect(d2.services[0].eventSubUrl,
        'http://192.168.1.2:49152/event?WFAWLANConfig');
  });
}
