part of '../../server.dart';

/// DLNA服务动作处理器接口
abstract class DlnaActionHandler {
  // AVTransport动作
  Future<void> setAVTransportURI(SetAVTransportURIInput input);
  Future<MediaInfo> getMediaInfo();
  Future<TransportInfo> getTransportInfo();
  Future<PositionInfo> getPositionInfo();
  Future<DeviceCapabilities> getDeviceCapabilities();
  Future<TransportSettings> getTransportSettings();
  Future<void> stop();
  Future<void> play(PlayInput input);
  Future<void> pause();
  Future<void> seek(SeekInput input);
  Future<void> next();
  Future<void> previous();

  // RenderingControl动作
  Future<bool> getMute(GetMuteInput input);
  Future<void> setMute(SetMuteInput input);
  Future<int> getVolume(GetVolumeInput input);
  Future<void> setVolume(SetVolumeInput input);
  Future<String> listPresets();
  Future<void> selectPreset(SelectPresetInput input);

  // ConnectionManager动作
  String getProtocolInfo();
}

class DlnaService extends UpnpHostService {
  final String serviceType;
  final String serviceId;
  final List<UpnpHostAction> _actions;
  final DlnaActionHandler handler;

  DlnaService._({
    required this.serviceType,
    required this.serviceId,
    required List<UpnpHostAction> actions,
    required this.handler,
    super.simpleName,
  }) : _actions = actions;

  @override
  List<UpnpHostAction> get actions => _actions;

  @override
  String get type => serviceType;

  @override
  String get id => serviceId;

  static DlnaService createAVTransport(DlnaActionHandler handler) {
    return DlnaService._(
      simpleName: 'AVTransport',
      serviceType: DlnaProtocol.AV_TRANSPORT,
      serviceId: 'urn:upnp-org:serviceId:AVTransport',
      handler: handler,
      actions: [
        UpnpHostAction(
          'SetAVTransportURI',
          handler: (inputs) async {
            await handler.setAVTransportURI(SetAVTransportURIInput(
              currentURI: inputs['CurrentURI'] ?? '',
              currentURIMetaData: inputs['CurrentURIMetaData'],
            ));
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'GetMediaInfo',
          handler: (inputs) async {
            final result = await handler.getMediaInfo();
            return result.toMap();
          },
        ),
        UpnpHostAction(
          'GetTransportInfo',
          handler: (inputs) async {
            final result = await handler.getTransportInfo();
            return result.toMap();
          },
        ),
        UpnpHostAction(
          'GetPositionInfo',
          handler: (inputs) async {
            final result = await handler.getPositionInfo();
            return result.toMap();
          },
        ),
        UpnpHostAction(
          'GetDeviceCapabilities',
          handler: (inputs) async {
            final result = await handler.getDeviceCapabilities();
            return result.toMap();
          },
        ),
        UpnpHostAction(
          'GetTransportSettings',
          handler: (inputs) async {
            final result = await handler.getTransportSettings();
            return result.toMap();
          },
        ),
        UpnpHostAction(
          'Stop',
          handler: (inputs) async {
            await handler.stop();
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'Play',
          handler: (inputs) async {
            await handler.play(PlayInput(
              currentURI: inputs['CurrentURI'] ?? '',
              currentURIMetaData: inputs['CurrentURIMetaData'],
            ));
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'Pause',
          handler: (inputs) async {
            await handler.pause();
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'Seek',
          handler: (inputs) async {
            await handler.seek(SeekInput(
              relTime: inputs['RelTime'] ?? '00:00:00',
              absTime: inputs['AbsTime'] ?? '00:00:00',
            ));
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'Next',
          handler: (inputs) async {
            await handler.next();
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'Previous',
          handler: (inputs) async {
            await handler.previous();
            return {'Result': 'OK'};
          },
        ),
      ],
    );
  }

  // 创建RenderingControl服务
  static DlnaService createRenderingControl(DlnaActionHandler handler) {
    return DlnaService._(
      simpleName: 'RenderingControl',
      serviceType: DlnaProtocol.RENDERING_CONTROL,
      serviceId: 'urn:upnp-org:serviceId:RenderingControl',
      handler: handler,
      actions: [
        UpnpHostAction(
          'GetMute',
          handler: (inputs) async {
            final result = await handler.getMute(GetMuteInput(
              currentMute: inputs['CurrentMute'] ?? '0',
            ));
            return {'CurrentMute': result ? '1' : '0'};
          },
        ),
        UpnpHostAction(
          'SetMute',
          handler: (inputs) async {
            await handler.setMute(SetMuteInput(
              currentMute: inputs['CurrentMute'] == '1',
            ));
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'GetVolume',
          handler: (inputs) async {
            final result = await handler.getVolume(GetVolumeInput(
              currentVolume: inputs['CurrentVolume'] ?? '100',
            ));
            return {'CurrentVolume': result.toString()};
          },
        ),
        UpnpHostAction(
          'SetVolume',
          handler: (inputs) async {
            await handler.setVolume(SetVolumeInput(
              currentVolume: int.parse(inputs['CurrentVolume'] ?? '100'),
            ));
            return {'Result': 'OK'};
          },
        ),
        UpnpHostAction(
          'ListPresets',
          handler: (inputs) async {
            final result = await handler.listPresets();
            return {'CurrentPresetNameList': result};
          },
        ),
        UpnpHostAction(
          'SelectPreset',
          handler: (inputs) async {
            await handler.selectPreset(SelectPresetInput(
              currentPresetName: inputs['CurrentPresetName'] ?? '',
            ));
            return {'Result': 'OK'};
          },
        ),
      ],
    );
  }

  // 创建ConnectionManager服务
  static DlnaService createConnectionManager(DlnaActionHandler handler) {
    return DlnaService._(
      simpleName: 'ConnectionManager',
      serviceType: DlnaProtocol.CONNECTION_MANAGER,
      serviceId: 'urn:upnp-org:serviceId:ConnectionManager',
      handler: handler,
      actions: [
        UpnpHostAction(
          'GetProtocolInfo',
          handler: (inputs) async {
            return {
              'Source': handler.getProtocolInfo(),
              'Sink': '',
            };
          },
        ),
        UpnpHostAction(
          'GetCurrentConnectionIDs',
          handler: (inputs) async {
            return {
              'ConnectionIDs': '0',
            };
          },
        ),
        UpnpHostAction(
          'GetCurrentConnectionInfo',
          handler: (inputs) async {
            return {
              'RcsID': '0',
              'AVTransportID': '0',
              'ProtocolInfo': '',
              'PeerConnectionManager': '',
              'PeerConnectionID': '-1',
              'Direction': 'Output',
              'Status': 'OK',
            };
          },
        ),
      ],
    );
  }
}
