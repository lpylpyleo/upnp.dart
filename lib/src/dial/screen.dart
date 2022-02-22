part of upnp.dial;

class DialScreen {
  static Stream<DialScreen> find({
    bool silent = true}) async* {
    final discovery = DeviceDiscoverer();
    final ids = <String?>{};

    await for (DiscoveredClient client in discovery.quickDiscoverClients(
        timeout: const Duration(seconds: 5), query: CommonDevices.dial)) {
      if (ids.contains(client.usn)) {
        continue;
      }
      ids.add(client.usn);

      try {
        final dev = await (client.getDevice() as FutureOr<Device>);
        yield DialScreen(
            Uri.parse(Uri.parse(client.location!).origin), dev.friendlyName);
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }
  }

  final Uri baseUri;
  final String? name;

  DialScreen(this.baseUri, this.name);

  factory DialScreen.forCastDevice(String ip, String deviceName) {
    return DialScreen(Uri.parse('http://$ip:8008/'), deviceName);
  }

  Future<bool> isIdle() async {
    HttpClientResponse? response;

    try {
      response = await send('GET', '/apps');
      if (response.statusCode == 302) {
        return false;
      }
      return true;
    } finally {
      if (response != null) {
        await response.drain();
      }
    }
  }

  Future launch(String app, {payload}) async {
    if (payload is Map) {
      var out = '';
      for (String key in payload.keys as Iterable<String>) {
        if (out.isNotEmpty) {
          out += '&';
        }

        out +=
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(payload[key].toString())}';
      }
      payload = out;
    }

    HttpClientResponse? response;
    try {
      response = await send('POST', '/apps/$app', body: payload);
      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } finally {
      if (response != null) {
        await response.drain();
      }
    }
  }

  Future<bool> hasApp(String app) async {
    HttpClientResponse? response;
    try {
      response = await send('GET', '/apps/$app');
      if (response.statusCode == 404) {
        return false;
      }
      return true;
    } finally {
      if (response != null) {
        await response.drain();
      }
    }
  }

  Future<String?> getCurrentApp() async {
    HttpClientResponse? response;
    try {
      response = await send('GET', '/apps');
      if (response.statusCode == 302) {
        final loc = response.headers.value('location')!;
        final uri = Uri.parse(loc);
        return uri.pathSegments[1];
      }
      return null;
    } finally {
      if (response != null) {
        await response.drain();
      }
    }
  }

  Future<bool> close([String? app]) async {
    final toClose = app ?? await getCurrentApp();
    if (toClose != null) {
      HttpClientResponse? response;
      try {
        response = await send('DELETE', '/apps/$toClose');
        if (response.statusCode != 200) {
          return false;
        }
        return true;
      } finally {
        if (response != null) {
          await response.drain();
        }
      }
    }
    return false;
  }

  Future<HttpClientResponse> send(
    String method,
    String path, {
      body,
      Map<String, dynamic>? headers
  }) async {
    final request =
        await UpnpCommon.httpClient.openUrl(method, baseUri.resolve(path));

    if (body is String) {
      request.write(body);
    } else if (body is List<int>) {
      request.add(body);
    }

    if (headers != null) {
      for (String key in headers.keys) {
        request.headers.set(key, headers[key] as Object);
      }
    }

    return await request.close();
  }
}
