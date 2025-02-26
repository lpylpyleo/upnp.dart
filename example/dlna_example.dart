import 'dart:io';
import 'package:upnp2/server.dart';

/// 简单的媒体播放器实现
class SimpleMediaPlayer {
  String? _currentUri;
  TransportState _state = TransportState.noMediaPresent;
  int _volume = 50;
  bool _isMuted = false;

  void setSource(String uri) {
    _currentUri = uri;
    _state = TransportState.stopped;
    print('设置媒体源: $uri');
  }

  void play() {
    if (_currentUri != null) {
      _state = TransportState.playing;
      print('开始播放: $_currentUri');
    }
  }

  void pause() {
    if (_state == TransportState.playing) {
      _state = TransportState.pausedPlayback;
      print('暂停播放');
    }
  }

  void stop() {
    if (_state != TransportState.noMediaPresent) {
      _state = TransportState.stopped;
      print('停止播放');
    }
  }

  void setVolume(int volume) {
    _volume = volume.clamp(0, 100);
    print('设置音量: $_volume');
  }

  void setMute(bool mute) {
    _isMuted = mute;
    print('设置静音: $_isMuted');
  }

  TransportState get state => _state;
  int get volume => _volume;
  bool get isMuted => _isMuted;
  String? get currentUri => _currentUri;
}

/// DLNA动作处理器实现
class MyDlnaHandler implements DlnaActionHandler {
  final SimpleMediaPlayer player;

  MyDlnaHandler(this.player);

  @override
  Future<void> setAVTransportURI(SetAVTransportURIInput input) async {
    player.setSource(input.currentURI);
  }

  @override
  Future<MediaInfo> getMediaInfo() async {
    return MediaInfo(
      currentURI: player.currentUri ?? '',
      mediaDuration: '00:00:00', // 示例中未实现实际时长
    );
  }

  @override
  Future<TransportInfo> getTransportInfo() async {
    return TransportInfo(
      currentTransportState: player.state.toString(),
    );
  }

  @override
  Future<PositionInfo> getPositionInfo() async {
    return PositionInfo(
      trackURI: player.currentUri ?? '',
    );
  }

  @override
  Future<DeviceCapabilities> getDeviceCapabilities() async {
    return DeviceCapabilities();
  }

  @override
  Future<TransportSettings> getTransportSettings() async {
    return TransportSettings();
  }

  @override
  Future<void> stop() async {
    player.stop();
  }

  @override
  Future<void> play(PlayInput input) async {
    player.play();
  }

  @override
  Future<void> pause() async {
    player.pause();
  }

  @override
  Future<void> seek(SeekInput input) async {
    // 示例中未实现实际跳转
    print('跳转到: ${input.target}');
  }

  @override
  Future<void> next() async {
    print('下一曲 (未实现)');
  }

  @override
  Future<void> previous() async {
    print('上一曲 (未实现)');
  }

  @override
  Future<bool> getMute(GetMuteInput input) async {
    return player.isMuted;
  }

  @override
  Future<void> setMute(SetMuteInput input) async {
    player.setMute(input.currentMute);
  }

  @override
  Future<int> getVolume(GetVolumeInput input) async {
    return player.volume;
  }

  @override
  Future<void> setVolume(SetVolumeInput input) async {
    player.setVolume(input.currentVolume);
  }

  @override
  Future<String> listPresets() async {
    return 'FactoryDefaults';
  }

  @override
  Future<void> selectPreset(SelectPresetInput input) async {
    print('选择预设: ${input.currentPresetName}');
  }

  @override
  String getProtocolInfo() {
    return 'http-get:*:video/mp4:*,http-get:*:audio/mp3:*,http-get:*:audio/mpeg:*';
  }
}

void main() async {
  // 创建媒体播放器和DLNA处理器
  final player = SimpleMediaPlayer();
  final handler = MyDlnaHandler(player);

  // 创建DLNA设备
  final device = UpnpHostDevice(
    deviceType: DlnaProtocol.MEDIA_RENDERER,
    services: [
      DlnaService.createAVTransport(handler),
      DlnaService.createRenderingControl(handler),
      DlnaService.createConnectionManager(handler),
    ],
  );

  // 创建DLNA服务器
  final server = DlnaServer(
    device: device,
    deviceUuid: '38323636-4558-4dda-9100-4e2a68c8c0d4',
    friendlyName: 'Dart DLNA Player',
  );

  // 启动HTTP服务器
  final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('DLNA服务器运行在: ${httpServer.address.address}:${httpServer.port}');

  // 创建SSDP发现服务
  final discovery = UpnpDiscoveryServer(
    device,
    'http://${httpServer.address.address}:${httpServer.port}/upnp/root.xml',
  );

  // 启动SSDP发现服务
  await discovery.start();
  print('SSDP发现服务已启动');

  // 处理HTTP请求
  await for (HttpRequest request in httpServer) {
    await server.handleRequest(request);
  }

  // 程序结束时关闭发现服务
  ProcessSignal.sigint.watch().listen((_) async {
    await discovery.stop();
    await httpServer.close();
    exit(0);
  });
}
