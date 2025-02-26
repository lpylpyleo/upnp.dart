part of '../../server.dart';

/// DLNA协议处理类
class DlnaProtocol {
  static const String UPNP_VERSION = '1.0';
  static const String DLNA_VERSION = '1.50';

  // DLNA必需的服务类型
  static const String RENDERING_CONTROL = 'urn:schemas-upnp-org:service:RenderingControl:1';
  static const String AV_TRANSPORT = 'urn:schemas-upnp-org:service:AVTransport:1';
  static const String CONNECTION_MANAGER = 'urn:schemas-upnp-org:service:ConnectionManager:1';

  // DLNA设备类型
  static const String ROOT_DEVICE = 'urn:schemas-upnp-org:device:RootDevice:1';
  static const String MEDIA_RENDERER = 'urn:schemas-upnp-org:device:MediaRenderer:1';
  static const String MEDIA_SERVER = 'urn:schemas-upnp-org:device:MediaServer:1';
  static const String MEDIA_PLAYER = 'urn:schemas-upnp-org:device:MediaPlayer:1';

  // DLNA所需的响应头
  static Map<String, String> getDlnaHeaders() {
    return {
      'Content-Type': 'text/xml; charset="utf-8"',
      'Server': 'Linux/1.0 UPnP/1.0 Dart-DLNA/1.0',
      'EXT': '',
      'CONTENT-LANGUAGE': 'en',
    };
  }

  /// DLNA设备描述模板
  static String getDeviceDescription({
    required String deviceUuid,
    required String friendlyName,
    required String manufacturer,
    required String modelName,
    required String baseUrl,
  }) {
    // 确保baseUrl以/结尾
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    // 移除多余的upnp/路径
    final cleanBaseUrl = normalizedBaseUrl.replaceAll(RegExp(r'upnp/.*$'), '');

    return '''<?xml version="1.0" encoding="utf-8"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <specVersion>
    <major>1</major>
    <minor>0</minor>
  </specVersion>
  <device>
    <deviceType>$MEDIA_RENDERER</deviceType>
    <friendlyName>$friendlyName</friendlyName>
    <manufacturer>$manufacturer</manufacturer>
    <manufacturerURL>https://github.com/yourusername/your-project</manufacturerURL>
    <modelDescription>DLNA Media Renderer</modelDescription>
    <modelName>$modelName</modelName>
    <modelNumber>1</modelNumber>
    <modelURL>https://github.com/yourusername/your-project</modelURL>
    <serialNumber>$deviceUuid</serialNumber>
    <UDN>uuid:$deviceUuid</UDN>
    <serviceList>
      <service>
        <serviceType>$CONNECTION_MANAGER</serviceType>
        <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
        <SCPDURL>${cleanBaseUrl}upnp/services/ConnectionManager.xml</SCPDURL>
        <controlURL>${cleanBaseUrl}upnp/control/ConnectionManager</controlURL>
        <eventSubURL>${cleanBaseUrl}upnp/event/ConnectionManager</eventSubURL>
      </service>
      <service>
        <serviceType>$RENDERING_CONTROL</serviceType>
        <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
        <SCPDURL>${cleanBaseUrl}upnp/services/RenderingControl.xml</SCPDURL>
        <controlURL>${cleanBaseUrl}upnp/control/RenderingControl</controlURL>
        <eventSubURL>${cleanBaseUrl}upnp/event/RenderingControl</eventSubURL>
      </service>
      <service>
        <serviceType>$AV_TRANSPORT</serviceType>
        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
        <SCPDURL>${cleanBaseUrl}upnp/services/AVTransport.xml</SCPDURL>
        <controlURL>${cleanBaseUrl}upnp/control/AVTransport</controlURL>
        <eventSubURL>${cleanBaseUrl}upnp/event/AVTransport</eventSubURL>
      </service>
    </serviceList>
  </device>
</root>''';
  }

  // 媒体格式
  static const Map<String, String> MIME_TYPES = {
    // 视频格式
    'mp4': 'video/mp4',
    'mkv': 'video/x-matroska',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'ts': 'video/MP2T',
    'm3u8': 'application/x-mpegURL',

    // 音频格式
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',

    // 图片格式
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
  };

  // DLNA功能标识
  static const String DLNA_FEATURES = 'DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_CI=0';

  // 传输协议
  static const String HTTP_GET = 'http-get';
  static const String RTSP_RTP = 'rtsp-rtp-udp';

  // 播放模式
  static const String PLAY_MODE_NORMAL = 'NORMAL';
  static const String PLAY_MODE_REPEAT_ONE = 'REPEAT_ONE';
  static const String PLAY_MODE_REPEAT_ALL = 'REPEAT_ALL';
  static const String PLAY_MODE_RANDOM = 'RANDOM';
  static const String PLAY_MODE_SHUFFLE = 'SHUFFLE';

  // 搜索目标
  static const String SEARCH_ROOT = 'upnp:rootdevice';
  static const String SEARCH_ALL = 'ssdp:all';
  static const String SEARCH_MEDIA_RENDERER = 'urn:schemas-upnp-org:device:MediaRenderer:1';
  static const String SEARCH_MEDIA_SERVER = 'urn:schemas-upnp-org:device:MediaServer:1';

  /// 获取完整的协议信息字符串
  static String getProtocolInfo({
    String protocol = HTTP_GET,
    String mimeType = '*',
    String features = '*',
  }) =>
      '$protocol:*:$mimeType:$features';

  /// 获取支持的媒体格式列表
  static String getSupportedFormats() {
    return MIME_TYPES.values.map((mime) => getProtocolInfo(mimeType: mime)).join(',');
  }

  /// 检查文件扩展名是否支持
  static bool isSupportedExtension(String extension) {
    return MIME_TYPES.containsKey(extension.toLowerCase());
  }

  /// 根据文件扩展名获取MIME类型
  static String? getMimeType(String extension) {
    return MIME_TYPES[extension.toLowerCase()];
  }

  /// 根据MIME类型判断媒体类型
  static MediaType getMediaType(String mimeType) {
    if (mimeType.startsWith('video/')) return MediaType.video;
    if (mimeType.startsWith('audio/')) return MediaType.audio;
    if (mimeType.startsWith('image/')) return MediaType.image;
    return MediaType.unknown;
  }
}

/// 媒体类型枚举
enum MediaType {
  video('VIDEO'),
  audio('AUDIO'),
  image('IMAGE'),
  unknown('UNKNOWN');

  const MediaType(this.value);
  final String value;

  @override
  String toString() => value;
}
