import 'package:intl/intl.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

Future<void> main() async {
  final channel = IOWebSocketChannel.connect('ws://localhost:4321');
  final client = json_rpc.Client(channel.cast<String>());

  client.sendRequest(
    'sayHello',
    {'firstName': 'Foo', 'lastName': 'Bar'},
  ).then((dynamic greet) {
    final time = DateTime.fromMillisecondsSinceEpoch(greet['time'] as int);
    print(
      '${greet['message']}, '
      '${greet['names']['first']} ${greet['names']['last']}! '
      "It's ${DateFormat.Hms().format(time)} now.",
    );

    client.close();
  }).catchError((dynamic e) => print(e));

  client.listen();
}
