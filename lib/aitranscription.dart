import 'dart:async';
import 'dart:convert';
import 'dart:io' as f;

import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
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
        primarySwatch: Colors.blue,
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
  late IO.Socket socket;
  late Timer _timer;
  late String _currentFilePath;

  //SE INICIA LA CONEXIÓN CON EL SOCKET
  _initSocket() {
    socket = IO.io(
        'http://10.0.2.2:3000', //DIRECCIÓN DEL LOCALHOST SERVER NODEJS
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders({'foo': 'bar'}) // optional
            .build());
    socket.on('connection', (_) => print('Socket conectado'));
    socket.on('disconnect', (_) => print('Socket desconectado'));
    setState(() {
      socket.on('transcript', (data) => _transcripts.add(data));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transcripción en tiempo real'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 25,
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
                    decoration: InputDecoration(
                        labelText: 'Ingrese el nombre de la grabación'),
                  ),
                  ElevatedButton(
                    //pruebaGET,pruebaSocket
                    onPressed: pruebaGET,
                    child: Text('Probar WebSocket'),
                  ),
                  ElevatedButton(
                    onPressed: isRecording ? null : iniciarGrabacion,
                    child: Text('Comenzar a grabar'),
                  ),
                  ElevatedButton(
                    onPressed: isRecording ? detenerGrabacion : null,
                    child: Text('Detener grabación'),
                  ),
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

  @override
  void initState() {
    super.initState();
    _initSocket(); //Se llama a la función para iniciar conexión de socket
    // Solicitar permiso de grabación de audio
    _requestAudioPermission();
  }

  void _requestAudioPermission() async {
    var status = await recorder.hasPermission();
    if (!status) {
      print("Permiso de audio no otorgado");
    }
  }

  // Iniciar grabación
  Future<void> iniciarGrabacion() async {
    setState(() {
      isRecording = true;
    });

    final path = await getTemporaryDirectory();
    final filename = '${DateTime.now().millisecondsSinceEpoch}.wav';
    final filePath = path.path + '/' + filename;

    if (await recorder.hasPermission()) {
      await recorder.start(RecordConfig(), path: filePath);
      Timer.periodic(Duration(seconds: 7), (timer) async {
        if (isRecording) {
          final path = await recorder.stop();
          print("ESTE ES EL PATH DEL AUDIO GRABADO EN ESTOS MOMENTOS");
          print(path);
          print(
              "ESTE ES EL PATH DEL AUDIO GRABADO EN ESTOS MOMENTOS EN OTRO FORMATO");
          var audio = await f.File(path!).readAsBytes();
          print(audio);
          //var bytes = await f.File(path!).readAsBytes();
          //print(path); // Path completo al archivo de audio grabado

          socket.emit('data', audio);
          iniciarGrabacion();
        }
      });
      socket.emit('start', filename);
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

  // Detener grabación
  Future<void> detenerGrabacion() async {
    setState(() {
      isRecording = false;
    });

    final path = await recorder.stop();
    var audio = await f.File(path!).readAsBytes();
    //var bytes = await f.File(path!).readAsBytes();
    print(path); // Path completo al archivo de audio grabado

    socket.emit('data', audio);
    socket.emit('stop');
  }

  Future<void> pruebaGET() async {
    final url = "http://10.0.2.2:3000/prueba"; //10.0.2.2 localhost en Flutter

    var request = http.MultipartRequest("GET", Uri.parse(url));

    var response = await request.send();
    if (response.statusCode == 200) {
      print(
          "Se estaleció comunicación correctamente ${await response.stream.bytesToString()}");
    } else {
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  void dispose() {
    super.dispose();
    socket!.off('connect');
    socket!.off('transcript');
    socket!.disconnect();
  }
}
