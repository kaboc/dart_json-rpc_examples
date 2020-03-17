import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

// See comments in peer_chat/bin/server.dart.
Future<void> main() async {
  final server = await HttpServer.bind('localhost', 4321);
  print('Server listening on port ${server.port}...');

  server.listen((HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    final channel = IOWebSocketChannel(socket);
    final peer = json_rpc.Peer(
      channel.cast<String>(),
      // This error handler does not seem to be called, but I'm not so sure.
      onUnhandledError: (dynamic error, dynamic stackTrace) {
        print(error);
        print(stackTrace);
      },
    );

    final numbers = <int>[];

    peer.registerMethod('calculate', (json_rpc.Parameters params) async {
      try {
        print('Received: ${params['number'].asInt}');
      } catch (_) {
        peer.sendNotification('result', {'message': 'Input correctly'});
        return;
      }

      numbers.add(params['number'].asInt);
      final sum = numbers.reduce((a, b) => a + b);
      final avg = sum / numbers.length;

      peer.sendNotification('result', {'message': numbers.toString()});
      await _wait();
      peer.sendNotification('result', {'message': 'Total: $sum'});
      await _wait();
      peer.sendNotification('result', {'message': 'Average: $avg'});
    });

    peer.listen().whenComplete(() => print('Client disconnected.'));
  });
}

Future<void> _wait() async {
  return await Future.delayed(const Duration(milliseconds: 100));
}
