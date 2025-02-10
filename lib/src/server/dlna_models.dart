part of '../../server.dart';

/// DLNA传输状态枚举
enum TransportState {
  playing('PLAYING'),
  pausedPlayback('PAUSED_PLAYBACK'),
  stopped('STOPPED'),
  noMediaPresent('NO_MEDIA_PRESENT');

  const TransportState(this.value);
  final String value;

  @override
  String toString() => value;
}

/// DLNA传输状态枚举
enum TransportStatus {
  ok('OK'),
  errorOccurred('ERROR_OCCURRED');

  const TransportStatus(this.value);
  final String value;

  @override
  String toString() => value;
}

/// AVTransport相关模型
class SetAVTransportURIInput {
  final String currentURI;
  final String? currentURIMetaData;
  final String instanceID;

  SetAVTransportURIInput({
    required this.currentURI,
    this.currentURIMetaData,
    this.instanceID = '0',
  });
}

class MediaInfo {
  final String nrTracks;
  final String mediaDuration;
  final String currentURI;
  final String currentURIMetaData;
  final String nextURI;
  final String nextURIMetaData;
  final String playMedium;
  final String recordMedium;
  final String writeStatus;

  MediaInfo({
    this.nrTracks = '1',
    this.mediaDuration = '00:00:00',
    this.currentURI = '',
    this.currentURIMetaData = '',
    this.nextURI = '',
    this.nextURIMetaData = '',
    this.playMedium = 'NONE',
    this.recordMedium = 'NOT_IMPLEMENTED',
    this.writeStatus = 'NOT_IMPLEMENTED',
  });

  Map<String, String> toMap() => {
        'NrTracks': nrTracks,
        'MediaDuration': mediaDuration,
        'CurrentURI': currentURI,
        'CurrentURIMetaData': currentURIMetaData,
        'NextURI': nextURI,
        'NextURIMetaData': nextURIMetaData,
        'PlayMedium': playMedium,
        'RecordMedium': recordMedium,
        'WriteStatus': writeStatus,
      };
}

class TransportInfo {
  final String currentTransportState;
  final String currentTransportStatus;
  final String currentSpeed;

  TransportInfo({
    required this.currentTransportState,
    this.currentTransportStatus = 'OK',
    this.currentSpeed = '1',
  });

  Map<String, String> toMap() => {
        'CurrentTransportState': currentTransportState,
        'CurrentTransportStatus': currentTransportStatus,
        'CurrentSpeed': currentSpeed,
      };
}

class PositionInfo {
  static const String UNKNOWN_COUNT = '2147483647'; // 2^31 - 1，表示未知或不适用

  final String track;
  final String trackDuration;
  final String trackMetaData;
  final String trackURI;
  final String relTime;
  final String absTime;
  final String relCount;
  final String absCount;

  PositionInfo({
    this.track = '1',
    this.trackDuration = '00:00:00',
    this.trackMetaData = '',
    this.trackURI = '',
    this.relTime = '00:00:00',
    this.absTime = '00:00:00',
    this.relCount = UNKNOWN_COUNT,
    this.absCount = UNKNOWN_COUNT,
  });

  Map<String, String> toMap() => {
        'Track': track,
        'TrackDuration': trackDuration,
        'TrackMetaData': trackMetaData,
        'TrackURI': trackURI,
        'RelTime': relTime,
        'AbsTime': absTime,
        'RelCount': relCount,
        'AbsCount': absCount,
      };
}

class DeviceCapabilities {
  final String playMedia;
  final String recMedia;
  final String recQualityModes;

  DeviceCapabilities({
    this.playMedia = 'NONE,NETWORK',
    this.recMedia = 'NOT_IMPLEMENTED',
    this.recQualityModes = 'NOT_IMPLEMENTED',
  });

  Map<String, String> toMap() => {
        'PlayMedia': playMedia,
        'RecMedia': recMedia,
        'RecQualityModes': recQualityModes,
      };
}

class TransportSettings {
  final String playMode;
  final String recQualityMode;

  TransportSettings({
    this.playMode = 'NORMAL',
    this.recQualityMode = 'NOT_IMPLEMENTED',
  });

  Map<String, String> toMap() => {
        'PlayMode': playMode,
        'RecQualityMode': recQualityMode,
      };
}

/// RenderingControl相关模型
class GetMuteInput {
  final String channel;
  final String instanceID;
  final String currentMute;

  GetMuteInput({
    this.channel = 'Master',
    this.instanceID = '0',
    required this.currentMute,
  });
}

class SetMuteInput {
  final String channel;
  final String instanceID;
  final bool currentMute;

  SetMuteInput({
    this.channel = 'Master',
    this.instanceID = '0',
    required this.currentMute,
  });
}

class GetVolumeInput {
  final String channel;
  final String instanceID;
  final String currentVolume;

  GetVolumeInput({
    this.channel = 'Master',
    this.instanceID = '0',
    required this.currentVolume,
  });
}

class SetVolumeInput {
  final String channel;
  final String instanceID;
  final int currentVolume;

  SetVolumeInput({
    this.channel = 'Master',
    this.instanceID = '0',
    required this.currentVolume,
  });
}

class SelectPresetInput {
  final String instanceID;
  final String currentPresetName;

  SelectPresetInput({
    this.instanceID = '0',
    required this.currentPresetName,
  });
}

/// 播放控制相关模型
class PlayInput {
  final String currentURI;
  final String? currentURIMetaData;
  final String speed;
  final String instanceID;

  PlayInput({
    required this.currentURI,
    this.currentURIMetaData,
    this.speed = '1',
    this.instanceID = '0',
  });
}

class SeekInput {
  final String unit;
  final String target;
  final String instanceID;
  final String relTime;
  final String absTime;

  SeekInput({
    this.unit = 'REL_TIME',
    this.target = '00:00:00',
    this.instanceID = '0',
    this.relTime = '00:00:00',
    this.absTime = '00:00:00',
  });
}
