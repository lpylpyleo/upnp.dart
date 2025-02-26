part of '../../server.dart';

final InternetAddress _v4Multicast = InternetAddress('239.255.255.250');
// final InternetAddress _v6Multicast = InternetAddress('FF05::C');

class UpnpDiscoveryServer {
  final UpnpHostDevice device;
  final String rootDescriptionUrl;

  UpnpDiscoveryServer(this.device, this.rootDescriptionUrl);

  RawDatagramSocket? _socket;
  Timer? _timer;
  late List<NetworkInterface> _interfaces;

  Future<void> start() async {
    await stop();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_socket != null) {
        notify();
      }
    });

    try {
      _socket = await RawDatagramSocket.bind('0.0.0.0', 1900);
    } catch (e, stack) {
      print('Error binding to socket: $e\n$stack');
      _socket = null;
      throw Exception('Failed to bind to socket');
    }

    _interfaces = await NetworkInterface.list();
    List<NetworkInterface> joinedInterfaces = [];
    for (var interface in _interfaces) {
      if (joinedInterfaces.contains(interface)) continue;
      try {
        _socket!.joinMulticast(_v4Multicast, interface);
        joinedInterfaces.add(interface);
      } catch (e) {
        // ignore
      }
    }

    if (joinedInterfaces.isEmpty) {
      throw Exception('Failed to join multicast on any interface');
    }

    print('Joined interfaces: ${joinedInterfaces.map((e) => e.name).join(', ')}');

    _socket!.broadcastEnabled = true;
    _socket!.multicastHops = 100;

    _socket!.listen((RawSocketEvent e) async {
      if (e == RawSocketEvent.read) {
        final packet = _socket!.receive()!;
        _socket!.writeEventsEnabled = true;

        try {
          final string = utf8.decode(packet.data);
          final lines = string.split('\r\n');
          final firstLine = lines.first;

          if (firstLine.trim().toUpperCase().startsWith('M-SEARCH')) {
            final map = <String, String>{};
            for (String line in lines.skip(1)) {
              if (line.trim().isEmpty) continue;
              if (!line.contains(':')) continue;
              final parts = line.split(':');
              final key = parts.first.trim();
              final value = parts.skip(1).join(':').trim();
              map[key.toUpperCase()] = value;
            }

            if (map['ST'] is String) {
              final search = map['ST'];
              final devices = await respondToSearch(search, packet, map);
              print('Responding to search for $search devices: ${devices.length}');
              for (var dev in devices) {
                _socket!.send(utf8.encode(dev), packet.address, packet.port);
              }
            }
          }
        } catch (e, stack) {
          print('Error processing SSDP packet: $e\n$stack');
        }
      }
    });

    await notify();
  }

  Future<List<String>> respondToSearch(String? target, Datagram pkt, Map<String, String> headers) async {
    final out = <String>[];

    void addDevice(String? profile) {
      final buff = StringBuffer();
      buff.write('HTTP/1.1 200 OK\r\n');
      buff.write('CACHE-CONTROL: max-age=180\r\n');
      buff.write('EXT:\r\n');
      buff.write('LOCATION: $rootDescriptionUrl\r\n');
      buff.write('SERVER: UPnP.dart/1.0\r\n');
      buff.write('ST: $profile\r\n');
      buff.write('USN: ${device.deviceType}::$profile\r\n');
      out.add(buff.toString());
    }

    if (target == 'ssdp:all') {
      addDevice(device.deviceType);

      for (UpnpHostService svc in device.services) {
        addDevice(svc.type);
      }
    } else if (target == device.deviceType || target == 'upnp:rootdevice') {
      addDevice(device.deviceType);
    } else if (target == device.udn) {
      addDevice(device.deviceType);
    }

    final svc = device.findService(target);

    if (svc != null) {
      addDevice(svc.type);
    }

    return out;
  }

  Future notify() async {
    if (_socket != null) {
      final buff = StringBuffer();
      buff.write('NOTIFY * HTTP/1.1\r\n');
      buff.write('HOST: 239.255.255.250:1900\r\n');
      buff.write('CACHE-CONTROL: max-age=10\r\n');
      buff.write('LOCATION: $rootDescriptionUrl\r\n');
      buff.write('NT: ${device.deviceType}\r\n');
      buff.write('NTS: ssdp:alive\r\n');
      buff.write('USN: uuid:${UpnpHostUtils.generateToken()}\r\n');
      final bytes = utf8.encode(buff.toString());
      _socket!.send(bytes, _v4Multicast, 1900);
    }
  }

  Future stop() async {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }
}
