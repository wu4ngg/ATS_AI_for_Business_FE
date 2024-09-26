import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final Map<String, dynamic>? json;
  final Map<String, dynamic>? llmOutput;
  ChatMessage({this.text = "", required this.isUserMessage, this.json, this.llmOutput});
  @override
  String toString() {
    return "text: '$text', json: $json, llmOutput: $llmOutput";
  }
}

List<Map<String, dynamic>> convertChatToChatHistoryFormat(
    List<ChatMessage> msg) {
  List<Map<String, dynamic>> tmp = [];
  for (int i = 0; i < msg.length; i += 2) {
    tmp.add({
      "inputs": {"question": msg[i].text},
      "outputs": {
        "answer":
            msg[i + 1].text == "" ? msg[i + 1].json.toString() : msg[i + 1].text
      }
    });
  }
  return List.generate(msg.length, (index) {
    return {};
  });
}

class ChatProvider extends ChangeNotifier {
  bool _isGeneratingMessage = false;
  bool get isGeneratingMessage => _isGeneratingMessage;
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages.reversed.toList();
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }
  void sendMessage(String messageText) async {
    _isGeneratingMessage = true;
    _messages.add(ChatMessage(text: messageText, isUserMessage: true));
    ChatMessage loadingMsg =
        ChatMessage(isUserMessage: false, text: "Đang suy nghĩ...");
    _messages.add(loadingMsg);
    notifyListeners();
    log(_messages.toString());
    final botResponse = await _sendToChatbot(messageText);
    _messages.remove(loadingMsg);
    _messages.add(ChatMessage(
        text: (botResponse is Map<String, dynamic>) ? "" : botResponse,
        isUserMessage: false,
        json: (botResponse is Map<String, dynamic>) ? botResponse : null));
    _isGeneratingMessage = false;
    log(_messages.toString());
    notifyListeners();
  }
  Future<dynamic> _sendToChatbot(String messageText) async {
    try {
      const apiUrl =
          'http://cv02.atsolutions.com.vn:8081/score';
      //Map<String, dynamic> json = {};
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Access-Control-Allow-Origin": "*",
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer QHeN1haVkfnpSvtcuhWt4Weum1IU6tJM',
        },
        body: jsonEncode({'question': messageText, 'chat_history': []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          Map<String, dynamic> json = jsonDecode(data["answer"]);
          if (json.values.toList()[0].isEmpty) {
            return "Không có dữ liệu.";
          }
          log(json.toString());
          return json;
        } catch (ex) {
          log(ex.toString());
          return data["answer"];
        }
      } else {
        String body = response.body;
        log(body);
        return body;
      }
    } catch (ex) {
      if (ex is http.ClientException) {
        http.ClientException excep = ex;
        log(excep.toString());
      }
      log(ex.toString());
      return ex.toString();
    }
  }
}
