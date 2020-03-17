import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

// README of json_rpc_2 says:
//   This package supports this directly using the Peer class, which
//   implements both Client and Server. It supports the same methods as
//   those classes, and automatically makes sure that every message from
//   the other endpoint is routed and handled correctly.
//
// Without any more information written there, it is unclear how to make
// use of the feature. So instead, both server and client methods are
// used manually at both endpoints in this example.
Future<void> main() async {
  final server = await HttpServer.bind('localhost', 4321);
  print('Server listening on port ${server.port}...');

  final peers = <int, json_rpc.Peer>{};
  int id = 0;

  server.listen((HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    final channel = IOWebSocketChannel(socket);

    final key = ++id;
    final peer = json_rpc.Peer(
      channel.cast<String>(),
      // This error handler does not seem to be called, but I'm not so sure.
      onUnhandledError: (dynamic error, dynamic stackTrace) {
        print(error);
        print(stackTrace);
      },
    );
    peers[key] = peer;
    print('Connected: #$key');

    peer.registerMethod('send', (json_rpc.Parameters params) async {
      print('Request from ${params['name'].asString} (#$key)');

      peers.forEach((k, p) {
        if (p != peer) {
          p.sendNotification('onReceive', params.asMap);
        }
      });
    });

    peer.listen().whenComplete(() {
      if (peers.containsKey(key)) {
        peers.remove(key);
        print('Disconnected: #$key');
      }
    });
  });
}
