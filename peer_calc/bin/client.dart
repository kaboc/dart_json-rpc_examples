import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

Future<void> main() async {
  final channel = IOWebSocketChannel.connect('ws://localhost:4321');
  final peer = json_rpc.Peer(
    channel.cast<String>(),
    // This error handler does not seem to be called, but I'm not so sure.
    onUnhandledError: (dynamic error, dynamic stackTrace) {
      print(error);
      print(stackTrace);
    },
  );

  print('Input a numerical value and then press Enter.');

  final subscription = requestStream().listen((number) {
    peer.sendNotification('calculate', {'number': number});
  });

  peer.registerMethod('result', (json_rpc.Parameters params) {
    print(params['message'].asString);
  });

  // See comments in peer_chat/bin/client.dart.
  try {
    await peer.listen().whenComplete(() {
      subscription.cancel();
    }).timeout(const Duration(seconds: 10));
  } on TimeoutException catch (e) {
    peer.close();
    print(e);
  } catch (e) {
    print(e);
  }
}

Stream<int> requestStream() {
  return stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .transform<int>(toInt());
}

StreamTransformer<String, int> toInt() {
  return StreamTransformer<String, int>.fromHandlers(
    handleData: (value, sink) {
      try {
        sink.add(int.parse(value));
      } catch (_) {
        sink.add(null);
      }
    },
  );
}
