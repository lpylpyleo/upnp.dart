part of upnp.router;

class Router {
  static Future<Router?> find() async {
    try {
      final discovery = DeviceDiscoverer();
      final client = await discovery
          .quickDiscoverClients(
              timeout: const Duration(seconds: 10),
              query: CommonDevices.wanRouter)
          .first;

      final device = await client.getDevice();
      discovery.stop();
      final router = Router(device);
      await router.init();
      return router;
    } catch (e) {
      return null;
    }
  }

  static Stream<Router> findAll(
      {bool silent = true,
      bool unique = true,
      bool enableIpv4Only = true,
      Duration timeout = const Duration(seconds: 10)}) async* {
    final discovery = DeviceDiscoverer();
    await discovery.start(ipv4: true, ipv6: !enableIpv4Only);
    await for (DiscoveredClient client in discovery.quickDiscoverClients(
        timeout: timeout, query: CommonDevices.wanRouter, unique: unique)) {
      try {
        final device = await client.getDevice();
        final router = Router(device);
        await router.init();
        yield router;
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }
  }

  final Device? device;

  Service? _wanExternalService;
  Service? _wanCommonService;
  Service? _wanEthernetLinkService;

  Router(this.device);

  bool get hasEthernetLink => _wanEthernetLinkService != null;

  Future init() async {
    _wanExternalService =
        await device!.getService('urn:upnp-org:serviceId:WANIPConn1');
    _wanCommonService =
        await device!.getService('urn:upnp-org:serviceId:WANCommonIFC1');
    _wanEthernetLinkService =
        await device!.getService('urn:upnp-org:serviceId:WANEthLinkC1');
  }

  Future<String?> getExternalIpAddress() async {
    final result =
        await _wanExternalService!.invokeAction('GetExternalIPAddress', {});
    return result['NewExternalIPAddress'];
  }

  Future<int> getTotalBytesSent() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalBytesSent', {});
    return num.tryParse(result['NewTotalBytesSent']!) as FutureOr<int>? ?? 0;
  }

  Future<int> getTotalBytesReceived() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalBytesReceived', {});
    return num.tryParse(result['NewTotalBytesReceived']!) as FutureOr<int>? ??
        0;
  }

  Future<int> getTotalPacketsSent() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalPacketsSent', {});
    return num.tryParse(result['NewTotalPacketsSent']!) as FutureOr<int>? ?? 0;
  }

  Future<int> getTotalPacketsReceived() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalPacketsReceived', {});
    return num.tryParse(result['NewTotalPacketsReceived']!) as FutureOr<int>? ??
        0;
  }
}
