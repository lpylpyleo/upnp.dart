part of '../../router.dart';

/// Represents an upnp enabled router
class Router {
  /// Returns the first router found or null if none was found
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

  /// Returns a stream of discovered devices with DIAL capabilities.
  /// If unique, already found devices won't be added again to the stream.
  /// If silent, no exceptions will be passed to the returned stream.
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

  /// The according device to this router
  final Device? device;

  Service? _wanExternalService;
  Service? _wanCommonService;
  Service? _wanEthernetLinkService;

  /// Initializes this router with a specific device
  Router(this.device);

  /// Returns if this router has an ethernet link
  bool get hasEthernetLink => _wanEthernetLinkService != null;

  /// Starts gathering information about this router.
  /// This method does not have to be called if the device was found via [Router.find()] or [Router.findAll()]
  Future init() async {
    _wanExternalService =
        await device!.getService('urn:upnp-org:serviceId:WANIPConn1');
    _wanCommonService =
        await device!.getService('urn:upnp-org:serviceId:WANCommonIFC1');
    _wanEthernetLinkService =
        await device!.getService('urn:upnp-org:serviceId:WANEthLinkC1');
  }

  /// Returns the external ip address of this router or null if it has none
  Future<String?> getExternalIpAddress() async {
    final result =
        await _wanExternalService!.invokeAction('GetExternalIPAddress', {});
    return result['NewExternalIPAddress'];
  }

  /// Returns the amount of total bytes sent since the router is up/tracking statistics
  Future<int> getTotalBytesSent() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalBytesSent', {});
    return num.tryParse(result['NewTotalBytesSent']!) as FutureOr<int>? ?? 0;
  }

  /// Returns the amount of total received sent since the router is up/tracking statistics
  Future<int> getTotalBytesReceived() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalBytesReceived', {});
    return num.tryParse(result['NewTotalBytesReceived']!) as FutureOr<int>? ??
        0;
  }

  /// Returns the amount of total packets sent since the router is up/tracking statistics
  Future<int> getTotalPacketsSent() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalPacketsSent', {});
    return num.tryParse(result['NewTotalPacketsSent']!) as FutureOr<int>? ?? 0;
  }

  /// Returns the amount of total received sent since the router is up/tracking statistics
  Future<int> getTotalPacketsReceived() async {
    final result =
        await _wanCommonService!.invokeAction('GetTotalPacketsReceived', {});
    return num.tryParse(result['NewTotalPacketsReceived']!) as FutureOr<int>? ??
        0;
  }
}
