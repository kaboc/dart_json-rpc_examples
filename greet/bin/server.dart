import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

Future<void> main() async {
  final server = await HttpServer.bind('localhost', 4321);
  print('Server listening on port ${server.port}...');

  server.listen((HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    final channel = IOWebSocketChannel(socket);
    final server = json_rpc.Server(
      channel.cast<String>(),
      // This error handler does not seem to be called, but I'm not so sure.
      onUnhandledError: (dynamic error, dynamic stackTrace) {
        print(error);
        print(stackTrace);
      },
    );

    server.registerMethod('sayHello', (json_rpc.Parameters params) {
      final firstName = params['firstName'].asString;
      final lastName = params['lastName'].asString;
      print('Request from $firstName $lastName');

      final now = DateTime.now();

      return {
        'message': now.hour < 12 ? 'Good Morning' : 'Hi',
        'names': {
          'first': firstName,
          'last': lastName,
        },
        'time': now.millisecondsSinceEpoch,
      };
    });

    server.listen();
  });
}
