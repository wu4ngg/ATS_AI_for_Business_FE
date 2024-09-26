import 'package:dio/dio.dart';

Map<String, dynamic> header(String token) {
  return {
    "Access-Control-Allow-Origin": "*",
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
    'azureml-model-deployment': 'data-chatbot-2'
  };
}

class API {
  final Dio _dio = Dio();
  String baseUrl = "https://data-chatbot.canadaeast.inference.ml.azure.com";

  API() {
    _dio.options.baseUrl = "$baseUrl/score";
  }
  Dio get sendRequest => _dio;
}
