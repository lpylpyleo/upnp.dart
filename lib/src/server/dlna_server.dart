part of '../../server.dart';

class DlnaServer extends UpnpServer {
  final String deviceUuid;
  final String friendlyName;
  final String manufacturer;
  final String modelName;

  DlnaServer({
    required UpnpHostDevice device,
    required this.deviceUuid,
    required this.friendlyName,
    this.manufacturer = 'Dart DLNA',
    this.modelName = 'Dart Media Renderer',
  }) : super(device);

  @override
  Future handleRequest(HttpRequest request) async {
    final headers = DlnaProtocol.getDlnaHeaders();
    headers.forEach((key, value) {
      request.response.headers.add(key, value);
    });

    await super.handleRequest(request);
  }

  @override
  Future handleRootRequest(HttpRequest request) async {
    final baseUrl = request.requestedUri.toString();
    final xml = DlnaProtocol.getDeviceDescription(
      deviceUuid: deviceUuid,
      friendlyName: friendlyName,
      manufacturer: manufacturer,
      modelName: modelName,
      baseUrl: baseUrl,
    );

    request.response
      ..headers.contentType = UpnpServer._xmlType
      ..write(xml);
    await request.response.close();
  }
}
