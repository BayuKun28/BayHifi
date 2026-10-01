import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../exceptions/exceptions.dart';
import '../extensions/helpers_extension.dart';
import '../retry.dart';
import '../videos/streams/mixins/hls_stream_info.dart';
import '../videos/streams/streams.dart';
import 'hls_manifest.dart';

/// HttpClient wrapper for YouTube
class YoutubeHttpClient extends http.BaseClient {
  final http.Client _httpClient;
  static final _logger = Logger('YoutubeExplode.HttpClient');

  // Flag to interrupt receiving stream.
  bool _closed = false;

  bool get closed => _closed;

  static const Map<String, String> defaultHeaders = {
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'cookie': 'CONSENT=YES+cb',
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'accept-language': 'en-US,en;q=0.5',
  };

  /// For any custom YoutubeHttpClient to override headers easily
  Map<String, String> get headers => defaultHeaders;

  /// Initialize an instance of [YoutubeHttpClient]
  YoutubeHttpClient([http.Client? httpClient])
      : _httpClient = httpClient ?? http.Client();

  /// Throws if something is wrong with the response.
  void _validateResponse(http.BaseResponse response, int statusCode) {
    if (_closed) return;

    final request = response.request!;

    if (request.url.host.endsWith('.google.com') &&
        request.url.path.startsWith('/sorry/')) {
      throw RequestLimitExceededException.httpRequest(response);
    }

    if (statusCode >= 500) {
      throw TransientFailureException.httpRequest(response);
    }

    if (statusCode == 429) {
      throw RequestLimitExceededException.httpRequest(response);
    }

    if (statusCode >= 400) {
      throw FatalFailureException.httpRequest(response);
    }
  }

  ///
  Future<String> getString(
    dynamic url, {
    Map<String, String> headers = const {},
    bool validate = true,
  }) async {
    final response =
        await get(url is String ? Uri.parse(url) : url, headers: headers);
    if (_closed) throw HttpClientClosedException();

    if (validate) {
      _validateResponse(response, response.statusCode);
    }

    return response.body;
  }

  @override
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers = const {},
    bool validate = false,
  }) async {
    final response = await super.get(url, headers: headers);
    if (_closed) throw HttpClientClosedException();

    if (validate) {
      _validateResponse(response, response.statusCode);
    }

    //final now = DateTime.now();
    //_log(response.body,
    //    '${now.minute}.${now.second}.${now.millisecond}-${url.pathSegments.last}-GET');

    return response;
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool validate = false,
  }) async {
    final response =
        await super.post(url, headers: headers, body: body, encoding: encoding);
    if (_closed) throw HttpClientClosedException();

    if (validate) {
      _validateResponse(response, response.statusCode);
    }
    return response;
  }

  ///
  Future<String> postString(
    dynamic url, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    bool validate = true,
  }) async {
    assert(url is String || url is Uri);
    if (url is String) {
      url = Uri.parse(url);
    }
    final response = await post(url, headers: headers, body: json.encode(body));
    if (_closed) throw HttpClientClosedException();

    if (validate) {
      _validateResponse(response, response.statusCode);
    }

    return response.body;
  }

  Stream<List<int>> getStream(
    StreamInfo streamInfo, {
    Map<String, String> headers = const {},
    bool validate = true,
    int start = 0,
    int errorCount = 0,
    required StreamClient streamClient,
  }) {
    print('[YouTubeHttpClient] getStream called for tag=${streamInfo.tag}, fragments=${streamInfo.fragments.length}, isHls=${streamInfo is HlsStreamInfo}, size=${streamInfo.size.totalBytes}');
    if (streamInfo.fragments.isNotEmpty) {
      print('[YouTubeHttpClient] Dispatching to _getFragmentedStream (${streamInfo.fragments.length} fragments)');
      // DASH(fragmented) stream
      return _getFragmentedStream(
        streamInfo,
        headers: headers,
        validate: validate,
        start: start,
        errorCount: errorCount,
      );
    }
    if (streamInfo is HlsStreamInfo) {
      print('[YouTubeHttpClient] Dispatching to _getHlsStream');
      return _getHlsStream(streamInfo);
    }
    print('[YouTubeHttpClient] Dispatching to _getStream');
    // Normal stream
    return _getStream(
      streamInfo,
      streamClient: streamClient,
      headers: headers,
      validate: validate,
      start: start,
      errorCount: errorCount,
    );
  }

  Stream<List<int>> _getFragmentedStream(
    StreamInfo streamInfo, {
    Map<String, String> headers = const {},
    bool validate = true,
    int start = 0,
    int errorCount = 0,
  }) async* {
    // This is the base url.
    final url = streamInfo.url;
    print('[YouTubeHttpClient] _getFragmentedStream base url: $url');
    for (int i = 0; i < streamInfo.fragments.length; i++) {
      final fragment = streamInfo.fragments[i];
      print('[YouTubeHttpClient] Fetching fragment $i: ${fragment.path}');
      final req = await retry(
        this,
        () => get(Uri.parse(url.toString() + fragment.path)),
      );
      yield req.bodyBytes;
    }
  }

  Stream<List<int>> _getStream(
    StreamInfo streamInfo, {
    Map<String, String> headers = const {},
    bool validate = true,
    int start = 0,
    int errorCount = 0,
    required StreamClient streamClient,
  }) async* {
    var url = streamInfo.url;
    var bytesCount = start;
    // Google Video CDN limits Range requests to max 512KB per request for Android clients;
    // larger ranges (>= 1MB or full file) are rejected with HTTP 403 Forbidden.
    const chunkSize = 512 * 1024; // 512 KB
    while (!_closed && (streamInfo.size.totalBytes <= 0 || bytesCount < streamInfo.size.totalBytes)) {
      try {
        final response = await retry(this, () async {
          final from = bytesCount;
          final totalBytes = streamInfo.size.totalBytes;
          int to = from + chunkSize - 1;
          if (totalBytes > 0 && to >= totalBytes) {
            to = totalBytes - 1;
          }

          final request = http.Request('GET', url);
          request.headers['Range'] = 'bytes=$from-$to';
          return send(request);
        });
        if (validate) {
          try {
            _validateResponse(response, response.statusCode);
          } on FatalFailureException {
            final newManifest =
                await streamClient.getManifest(streamInfo.videoId);
            final stream = newManifest.streams
                .firstWhereOrNull((e) => e.tag == streamInfo.tag);
            if (stream == null) {
              _logger.severe(
                  'Error: Could not find the stream in the new manifest (due to Youtube error)');
              rethrow;
            }
            url = stream.url;
            continue;
          }
        }
        int receivedInThisChunk = 0;
        await for (final data in response.stream) {
          bytesCount += data.length;
          receivedInThisChunk += data.length;
          yield data;
        }
        if (receivedInThisChunk == 0) {
          // No more data received from server
          break;
        }
        errorCount = 0;
      } on HttpClientClosedException {
        break;
      } on Exception catch (_) {
        if (errorCount >= 5) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        yield* _getStream(
          streamInfo,
          streamClient: streamClient,
          headers: headers,
          validate: validate,
          start: bytesCount,
          errorCount: errorCount + 1,
        );
        break;
      }
    }
  }

  ///
  Future<int?> getContentLength(
    dynamic url, {
    Map<String, String> headers = const {},
    bool validate = true,
  }) async {
    final response = await head(url, headers: headers);
    if (_closed) throw HttpClientClosedException();

    if (validate) {
      _validateResponse(response, response.statusCode);
    }

    return int.tryParse(response.headers['content-length'] ?? '');
  }

  Future<JsonMap> sendContinuation(
    String action,
    String token, {
    Map<String, String>? headers,
  }) async =>
      sendPost(action, {'continuation': token}, headers: headers);

  /// Sends a call to the youtube api endpoint.
  Future<JsonMap> sendPost(String action, Map<String, dynamic> data,
      {Map<String, String>? headers}) {
    assert(action == 'next' || action == 'browse' || action == 'search');

    final url = Uri.parse(
      'https://www.youtube.com/youtubei/v1/$action?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
    );

    final body = {
      'context': const {
        'client': {
          'browserName': 'Chrome',
          'browserVersion': '133.0.0.0',
          'clientFormFactor': 'UNKNOWN_FORM_FACTOR',
          'clientName': "WEB",
          'clientVersion': "2.20250312.04.00",
        },
      },
      ...data,
    };

    return retry<JsonMap>(this, () async {
      final raw = await post(url, body: json.encode(body), headers: headers);
      if (_closed) throw HttpClientClosedException();

      //final now = DateTime.now();
      //_log(raw.body,
      //    '${now.minute}.${now.second}.${now.millisecond}-$action-POST');
      return json.decode(raw.body);
    });
  }

  Stream<List<int>> _getHlsStream(HlsStreamInfo stream) async* {
    final videoIndex = await getString(stream.url);
    final video = HlsManifest.parseVideoSegments(videoIndex);
    for (final segment in video) {
      final data = await get(Uri.parse(segment.url));
      yield data.bodyBytes;
    }
  }

  @override
  void close() {
    _closed = true;
    _httpClient.close();
  }

  //void _log(String str, String filename) {
  //  Directory('requests').createSync();
  //  File('requests/$filename.json')
  //      .writeAsStringSync('${StackTrace.current}\n$str');
  //}

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) throw HttpClientClosedException();

    final isGoogleVideo = request.url.host.contains('googlevideo.com');

    if (!isGoogleVideo) {
      // Apply default headers if they are not already present
      headers.forEach((key, value) {
        if (request.headers[key] == null) {
          request.headers[key] = headers[key]!;
        }
      });
    } else {
      if (request.headers['user-agent'] == null) {
        final clientParam = request.url.queryParameters['c'];
        if (clientParam == 'IOS') {
          request.headers['user-agent'] =
              'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)';
        } else if (clientParam == 'ANDROID_MUSIC') {
          request.headers['user-agent'] =
              'com.google.android.apps.youtube.music/7.02.51 (Linux; U; Android 14) gzip';
        } else {
          request.headers['user-agent'] =
              'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';
        }
      }
    }

    _logger.fine('Sending request: $request', null, StackTrace.current);
    _logger.finer('Request headers: ${request.headers}');
    if (request is http.Request) {
      _logger.finer('Request body: ${request.body}');
    }
    return _httpClient.send(request);
  }
}
