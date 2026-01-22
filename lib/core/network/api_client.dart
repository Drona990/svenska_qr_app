import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../utils/constant/Endpoints.dart';
import '../utils/constant/constant.dart';
import 'network_info.dart';

class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  ApiClient(this._dio, this._networkInfo) {
    _dio.options = BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isConnected = await _networkInfo.isConnected;
          if (!isConnected) {
            _showSnackBar("No Internet Connection");
            return handler.reject(
              DioException(
                requestOptions: options,
                error: "No Internet Connection",
                type: DioExceptionType.cancel,
              ),
            );
          }

          // Attach access token only if request is NOT public
          final isPublic = options.extra["isPublic"] == true;
          if (!isPublic) {
            final accessToken = await _getAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers["Authorization"] = "Bearer $accessToken";
            }
          }

          return handler.next(options);
        },
        onError: (e, handler) async {
          // Handle 401 => Refresh Token
          if (e.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retryRequest = await _retry(e.requestOptions);
              return handler.resolve(retryRequest);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ----------- Public Methods ----------- //
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParams, bool isPublic = false}) async {
    return await _dio.get(path,
        queryParameters: queryParams, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParams, bool isPublic = false}) async {
    return await _dio.post(path,
        data: data,
        queryParameters: queryParams,
        options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> put(String path,
      {dynamic data, Map<String, dynamic>? queryParams, bool isPublic = false}) async {
    return await _dio.put(path,
        data: data,
        queryParameters: queryParams,
        options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParams, bool isPublic = false}) async {
    return await _dio.delete(path,
        data: data,
        queryParameters: queryParams,
        options: Options(extra: {"isPublic": isPublic}));
  }

  // ----------- Private Helpers ----------- //
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      extra: requestOptions.extra, // keep isPublic flag
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<String?> _getAccessToken() async {
    try {
      return GetIt.I<String>(instanceName: "accessToken");
    } catch (_) {
      return null;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = GetIt.I<String>(instanceName: "refreshToken");
      if (refreshToken.isEmpty) return false;

      final response = await _dio.post("/api/token/refresh/", data: {
        "refresh_token": refreshToken,
      });

      final newAccessToken = response.data["access_token"];
      if (newAccessToken != null) {
        if (GetIt.I.isRegistered<String>(instanceName: "accessToken")) {
          GetIt.I.unregister<String>(instanceName: "accessToken");
        }
        GetIt.I.registerSingleton<String>(newAccessToken,
            instanceName: "accessToken");
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message) {
    final context = GetIt.I<GlobalKey<NavigatorState>>().currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
