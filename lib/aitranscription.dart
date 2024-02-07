import 'dart:convert';

import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

void main() async {
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
  List<String> _transcripts = [];
  final recorder = AudioRecorder();
  bool isRecording = false;

  IO.Socket socket = IO.io('http://10.0.2.2:3000',
      OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .setExtraHeaders({'foo': 'bar'}) // optional
          .build());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  ElevatedButton(
                    //pruebaGET,pruebaSocket
                    onPressed: pruebaSocket,
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
                  ElevatedButton(onPressed: isRecording ? detenerGrabacion : iniciarGrabacion,
                    child: Text(isRecording
                        ? 'Detener Grabación'
                        : 'Iniciar Grabación'),),
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
  Future<void> iniciarGrabacion() async {
    if(!isRecording){
      try{
        if(await recorder.hasPermission()){
          final path = await getTemporaryDirectory();
          //final filename = DateTime.now().millisecondsSinceEpoch.toString() + '.wav';
          final filename = "audioPruebaFinal" + '.wav';
          final filePath = path.path + '/' + filename;
          await recorder.start(const RecordConfig(), path: filePath);
          setState(() {
            isRecording = true;
          });
        }
      }catch (e){
        print("Eror: $e");
      }
    }
    // Mostrar un Snackbar para indicar que la grabación ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada'),
      ),
    );
  }

  Future<void> detenerGrabacion() async {
    if(isRecording){
      try{
        var audio = await recorder.stop();
        setState(() {
          isRecording = false;
        });
        socket.onConnect((data) => {
          print('Connected to server'),
          //MIENTRAS SE GRABA EL AUDIO ENVIAR PARTES DEL MISMO
          socket.emit("transcription",audio),
        });
        socket.onDisconnect((_) => print('disconnect'));
      }catch (e){
        print("Eror: $e");
      }
    }
    // Mostrar un Snackbar para indicar que la grabación ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación detenida'),
      ),
    );
  }
  void pruebaSocket() {
    /*socket.connect();
    socket.onConnect((_){
      print("Connection established");
      //socket.emit('message','Este es un mensaje de prueba desde flutter');
      socket.send('Este es un mensaje de prueba desde flutter' as List<String>);
    });*/
    /*socket.onConnect((_) => {
      print('Connected to server'),
      socket.emit('message','hola desde flutter PRUEBA 0010'),
      socket.on('message', (data) =>
        print("Respuesta del servidor: "+data),),
    });
    socket.onDisconnect((_) => print('disconnect'));*/
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
    socket.disconnect();
    socket.dispose();
    super.dispose();
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