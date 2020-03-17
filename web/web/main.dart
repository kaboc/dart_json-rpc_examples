import 'dart:html';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/html.dart';

void main() {
  final channel = HtmlWebSocketChannel.connect('ws://localhost:4321');
  final peer = json_rpc.Peer(channel.cast<String>());

  final ButtonElement button = querySelector('button');
  final InputElement name = querySelector('input[name=name]');
  final InputElement message = querySelector('input[name=message]');

  button.onClick.listen((_) async {
    if (name.value.isEmpty || message.value.isEmpty) {
      return;
    }

    addMessage(name.value, message.value);
    send(peer, name.value, message.value);
  });

  peer.registerMethod('onReceive', (json_rpc.Parameters params) {
    addMessage(params['name'].asString, params['message'].asString);
  });

  peer.listen();
}

void send(json_rpc.Peer peer, String name, String message) {
  peer.sendNotification('send', {'name': name, 'message': message});
}

void addMessage(String name, String message) {
  final UListElement messageList = querySelector('#msg-list');
  final newMessage = LIElement()..text = '[$name] $message';
  messageList.children.add(newMessage);
}
