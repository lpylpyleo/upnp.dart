part of '../../server.dart';

class UpnpHostUtils {
  static Future<String> getCurrentIp() async {
    final String ip =
        const String.fromEnvironment('upnp.host.ip', defaultValue: '');
    if (ip != '') {
      return ip;
    }

    final interfaces = await NetworkInterface.list();
    for (var iface in interfaces) {
      if (iface.name.startsWith('VirtualBox') ||
          iface.name.startsWith('VMWare') ||
          iface.name.startsWith('vm')) {
        continue;
      }

      for (var addr in iface.addresses) {
        if (addr.address.startsWith('192.') ||
            addr.address.startsWith('10.') ||
            addr.address.startsWith('172.')) {
          return addr.address;
        }
      }
    }

    return interfaces.first.addresses
        .firstWhere((x) => !x.isLoopback && !x.isLinkLocal)
        .address;
  }

  static String generateBasicId({int length = 30}) {
    final r0 = Random();
    final buffer = StringBuffer();
    for (int i = 1; i <= length; i++) {
      final r = Random(
          r0.nextInt(0x70000000) + (DateTime.now()).millisecondsSinceEpoch);
      final n = r.nextInt(50);
      if (n >= 0 && n <= 32) {
        final String letter = alphabet[r.nextInt(alphabet.length)];
        buffer.write(r.nextBool() ? letter.toLowerCase() : letter);
      } else if (n > 32 && n <= 43) {
        buffer.write(numbers[r.nextInt(numbers.length)]);
      } else if (n > 43) {
        buffer.write(specials[r.nextInt(specials.length)]);
      }
    }
    return buffer.toString();
  }

  static String generateToken({int length = 50}) {
    final r0 = Random();
    final buffer = StringBuffer();
    for (int i = 1; i <= length; i++) {
      final r = Random(
          r0.nextInt(0x70000000) + (DateTime.now()).millisecondsSinceEpoch);
      if (r.nextBool()) {
        final String letter = alphabet[r.nextInt(alphabet.length)];
        buffer.write(r.nextBool() ? letter.toLowerCase() : letter);
      } else {
        buffer.write(numbers[r.nextInt(numbers.length)]);
      }
    }
    return buffer.toString();
  }

  static const List<String> alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];

  static const List<int> numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  static const List<String> specials = ['@', '=', '_', '+', '-', '!', '.'];
}
