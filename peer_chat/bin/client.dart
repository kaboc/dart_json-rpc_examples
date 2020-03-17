import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Specify your name please.');
    return;
  }

  final channel = IOWebSocketChannel.connect('ws://localhost:4321');
  final peer = json_rpc.Peer(
    channel.cast<String>(),
    // This error handler does not seem to be called, but I'm not so sure.
    onUnhandledError: (dynamic error, dynamic stackTrace) {
      print(error);
      print(stackTrace);
    },
  );

  final subscription = postStream().listen((message) {
    peer.sendNotification('send', {'name': args[0], 'message': message});
  });

  peer.registerMethod('onReceive', (json_rpc.Parameters params) {
    print('[${params['name'].asString}] ${params['message'].asString}');
  });

  try {
    await peer
      .listen()
      .whenComplete(() {
        // Called
        // - when the server was terminated,
        // - when this client tries to connect to a server not running,
        // - or on timeout.
        //
        // If some error calls this method and another error is returned
        // from here (e.g. return Future.error(...)), it overrides the
        // original error. Be careful not to do so if you want the original
        // one to be caught by try-catch outside here.
        //
        // It is also true of timeout, if .timeout() is written before
        // .whenComplete().
        subscription.cancel();
      })
      // The counting does not restart every new request. It starts when
      // the client begins to listen, so this timeout setting may not
      // be very useful in the case that the app expects communication
      // between endpoints to last for a long period of time.
      .timeout(const Duration(seconds: 60));
  } on TimeoutException catch (e) {
    peer.close();
    print(e);
  } catch (e) {
    // No exception is caught when the server is terminated, so the client
    // just exits quietly in that case.
    print(e);
  }
}

Stream<String> postStream() {
  return stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter());
}
