import 'dart:convert';

import 'package:archonit_demo/core/logging_service.dart';
import 'package:archonit_demo/data/network/api_client.dart';
import 'package:archonit_demo/data/network/endpoints.dart';
import 'package:archonit_demo/data/network/params.dart';
import 'package:archonit_demo/domain/models/error_model.dart';
import 'package:archonit_demo/resources/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class ApiClientHttpImpl implements ApiClient {
  final http.Client _client;
  final Params _params;

  ApiClientHttpImpl(this._client, this._params);

  Future<Response> _handleResponseStatus({required Future<dynamic> apiCall}) async {
    final stopwatch = Stopwatch()..start();
    final response = await apiCall;
    stopwatch.stop();
    final elapsedTime = stopwatch.elapsedMilliseconds;

    LogService.printLog('+/SERVER RESPONSE DELAY: $elapsedTime MILLISECONDS /+');
    LogService.printLog('${response.statusCode} => ${response.reasonPhrase}');

    String body = utf8.decode(response.bodyBytes);
    switch (response.statusCode) {
      case (200):
        break;
      case (>= 400 && < 500 && != 422 && != 401):
        throw ErrorModel.fromJson(jsonDecode(body));
      case (401):
        throw ErrorModel.fromJson(jsonDecode(body));
      case (422):
      // throw ErrorDto(detail: ValidationErrorDto.fromJson(jsonDecode(body)).detail!.first.msg);
      case (>= 500 && < 600):
      // throw ErrorDto(detail: response.reasonPhrase);
    }

    return response;
  }

  Map<String, dynamic> _decoder(http.Response resp) {
    final body = utf8.decode(resp.bodyBytes);
    final data = jsonDecode(body);
    return data;
  }

  // GET
  @override
  Future<Map<String, dynamic>> get({required String endpoint, required Map<String, dynamic> queryParams}) async {
    final queryString = Uri(queryParameters: queryParams);
    final url = '${Endpoints.baseUrl}$endpoint$queryString';
    final resp = await _handleResponseStatus(
      apiCall: _client.get(Uri.parse(url), headers: _params.getHeaders(token: dotenv.env[AppStrings.apiToken])),
    );
    final data = _decoder(resp);
    return data;
  }
}
