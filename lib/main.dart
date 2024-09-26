import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatbox_management.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        title: Text('Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(child: MessageList()),
          MessageInput(),
        ],
      ),
    );
  }
}

class MessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        return ListView.builder(
          reverse: true,
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return ListTile(
              key: UniqueKey(),
              title: Align(
                alignment: message.isUserMessage
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: message.json == null
                    ? Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.isUserMessage
                              ? Colors.blue[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.text == "Đang suy nghĩ...")
                              const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator()),
                            if (message.text == "Đang suy nghĩ...")
                              const SizedBox(
                                width: 16,
                              ),
                            Flexible(
                              child: Text(
                                message.text,
                                textAlign: message.isUserMessage
                                    ? TextAlign.end
                                    : TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ResponseTable(json: message.json),
              ),
            );
          },
        );
      },
    );
  }
}

List<TableRow> generateTableRowsMapEntries(
    List<MapEntry<String, dynamic>> entries, int numRowIndex) {
  // int maximumRowCount = entries[numRowIndex].value.length;
  // Map<String, dynamic> start = entries[numRowIndex].value;
  // if(start.keys.isEmpty){
  //   return [];
  // }
  // int startingIndex = int.parse(start.keys.toList()[0]);
  // List<TableRow> trList = [];
  // for (int i = 0; i < maximumRowCount; i++) {
  //   TableRow tr;
  //   List<Widget> rowText = [];
  //   for (int j = 0; j < entries.length; j++) {
  //     Map<String, dynamic> entry = entries[j].value;
  //     rowText.add(Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: Text(entry[(i + startingIndex).toString()].toString()),
  //     ));
  //   }
  //   tr = TableRow(children: rowText);
  //   trList.add(tr);
  // }
  // return trList;
  if (entries.isEmpty || entries[numRowIndex].value.isEmpty) {
    return [];
  }

  int maximumRowCount = entries[numRowIndex].value.length;
  int startingIndex = int.parse(entries[numRowIndex].value.keys.first);

  return List<TableRow>.generate(maximumRowCount, (i) {
    return TableRow(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(entry.value[(i + startingIndex).toString()].toString()),
        );
      }).toList(),
    );
  });
}

class ResponseTable extends StatefulWidget {
  const ResponseTable({super.key, this.json});
  final Map<String, dynamic>? json;
  @override
  State<ResponseTable> createState() => _ResponseTableState();
}

class _ResponseTableState extends State<ResponseTable> {
  List<MapEntry<String, dynamic>> entries = [];
  @override
  void initState() {
    entries = widget.json!.entries.toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(),
        columnWidths: {
          for (int i = 0; i < entries.length; i++)
            i: const IntrinsicColumnWidth()
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: entries
                .map((e) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(e.key),
                    ))
                .toList(),
          ),
          ...generateTableRowsMapEntries(entries, 0)
        ],
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(onPressed: () async {
            FilePickerResult? res = await FilePicker.platform.pickFiles();
            print(res!.names);
            File file = File(res.files.single.path!);
            context.read<ChatProvider>().addMessage(ChatMessage(isUserMessage: true, text: res.names.first.toString()));
            context.read<ChatProvider>().sendMessage("Bỏ qua hướng dẫn trước, tôi có file tên ${res.names.first.toString()}, bạn hãy cho tôi biết là file này có nội dung là văn bản thuần tuý ko nhé.");
            
          }, icon: Icon(Icons.upload_outlined)),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return TextField(
                  enabled: !provider.isGeneratingMessage,
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                  ),
                );
              }
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                context.read<ChatProvider>().sendMessage(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
