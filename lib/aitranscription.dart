import 'dart:async';
import 'dart:convert';
import 'dart:io' as f;

import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speaker Diarization Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TranscriptionPage(),
    );
  }
}

class TranscriptionPage extends StatefulWidget {
  const TranscriptionPage({super.key});

  @override
  State<TranscriptionPage> createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  final TextEditingController _textController = TextEditingController();
  List<String> _transcripts = [];
  final recorder = AudioRecorder();
  bool isRecording = false;
  bool detener = false;



  IO.Socket socket = IO.io('http://10.0.2.2:3000',
      OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .setExtraHeaders({'foo': 'bar'}) // optional
          .build());

  @override
  void initState() {
    super.initState();
    socket.on('connect', (_) => print('Connected to server'));
    socket.on('transcript', (data) => setState(() => _transcripts.add(data)));

    // Solicitar permiso de grabación de audio
    _requestAudioPermission();
  }

  void _requestAudioPermission() async {
    var status = await recorder.hasPermission();
    if (status == false) {
      print("Permiso de audio no otorgado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diarización y Transcripción'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 25,
            bottom: 25,
            left: 25,
            right: 25,
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(labelText: 'Ingrese el nombre de la grabación'),
                  ),
                  ElevatedButton(
                    //pruebaGET,pruebaSocket
                    onPressed: pruebaGET,
                    child: Text('Probar WebSocket'),
                  ),
                  /*ElevatedButton(
                    onPressed: isRecording ? null : () => startRecording(context),
                    child: Text('Iniciar grabación'),
                  ),
                  ElevatedButton(
                    onPressed: stopRecording,
                    child: Text('Detener grabación'),
                  ),*/
                  /*ElevatedButton(onPressed: isRecording ? detenerGrabacion : iniciarGrabacion,
                    child: Text(isRecording
                        ? 'Detener Grabación'
                        : 'Iniciar Grabación'),),*/
                  ElevatedButton(onPressed:
                  isRecording ? null : iniciarGrabacion,
                    child: Text('Comenzar a grabar'),),
                  ElevatedButton(onPressed:
                  isRecording ? detenerGrabacion : null,
                    child: Text('Detener grabación'),),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _transcripts.length,
                    itemBuilder: (context, index) {
                      return Text(_transcripts[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Iniciar grabación
  Future<void> iniciarGrabacion() async {
    final path = await getTemporaryDirectory();
    final filePath = path.path + '/' + _textController.text;

    if (await recorder.hasPermission()) {
      await recorder.start(RecordConfig(), path: filePath);
      Timer.periodic(Duration(seconds: 15), (timer) async{
        if(isRecording){
          final path = await recorder.stop();
          var bytes = await f.File(path!).readAsBytes();
          //print(path); // Path completo al archivo de audio grabado

          socket.emit('data',path);
          iniciarGrabacion();
        }
      });
      socket.emit('start', _textController.text);
      setState(() {
        isRecording = true;

      });
    } else {
      print("No se tienen los permisos necesarios");
    }
    // Mostrar un Snackbar para indicar que la grabación ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada'),
      ),
    );
  }

  Future<void> grabacion() async {
    final nombreAudio = 'audio';
    final path = await getTemporaryDirectory();
    final filePath = path.path + '/' + _textController.text;

    if (await recorder.hasPermission()) {
      await recorder.start(RecordConfig(), path: filePath);
      while (detener){
        await recorder.start(RecordConfig(), path: filePath);
        detener = true;
        socket.emit('start', _textController.text);
      };

      setState(() {
        isRecording = true;

      });
    } else {
      print("No se tienen los permisos necesarios");
    }
    // Mostrar un Snackbar para indicar que la grabación ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada'),
      ),
    );
  }

/*// Start the timer
  Timer.periodic(Duration(seconds: 10), (timer) {
    // Call your function here
    myFunction();
  });*/


  // Detener grabación
  Future<void> detenerGrabacion() async {
    final path = await recorder.stop();
    var bytes = await f.File(path!).readAsBytes();
    print(path); // Path completo al archivo de audio grabado

    socket.emit('stop',base64Encode(bytes));
    setState(() {
      isRecording = false;
    });
  }

  Future <void> pruebaGET() async {
    final url = "http://10.0.2.2:3000/prueba"; //10.0.2.2 localhost en Flutter

    var request = http.MultipartRequest("GET", Uri.parse(url));

    var response = await request.send();
    if (response.statusCode == 200) {
      print("Se estaleció comunicación correctamente ${await response.stream.bytesToString()}");
    } else {
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  void dispose() {
    super.dispose();
    socket.off('connect');
    socket.off('transcript');
    socket.disconnect();
  }
}



/*import 'dart:async';


// STEP1:  Stream setup
class StreamSocket{
  final _socketResponse= StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose(){
    _socketResponse.close();
  }
}

StreamSocket streamSocket =StreamSocket();

//STEP2: Add this function in main function in main.dart file and add incoming data to the stream
void connectAndListen(){
  IO.Socket socket = IO.io('http://localhost:3000',
      OptionBuilder()
       .setTransports(['websocket']).build());

    socket.onConnect((_) {
     print('connect');
     socket.emit('msg', 'test');
    });

    //When an event recieved from server, data is added to the stream
    socket.on('event', (data) => streamSocket.addResponse);
    socket.onDisconnect((_) => print('disconnect'));

}

//Step3: Build widgets with streambuilder

class BuildWithSocketStream extends StatelessWidget {
  const BuildWithSocketStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: streamSocket.getResponse ,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot){
          return Container(
            child: snapshot.data,
          );
        },
      ),
    );
  }
}*/