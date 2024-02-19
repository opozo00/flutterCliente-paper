import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:modelos_paper/constant.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/*void main() {
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
      home: const MyHomePage(),
    );
  }
}*/

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRecording = false;
  final record = AudioRecorder();
  late String _transcription;
  List<String> _transcripts = [];
  bool _grabacionTerminada = false;

  Future<String> convertTextToSpeech(String filePath) async {
    const apiKey = apiSecretKey;
    var url = Uri.https("api.openai.com", "v1/audio/transcriptions");
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
    request.fields["model"] = 'whisper-1';
    request.fields["language"] = 'es';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();
    var newresponse = await http.Response.fromStream(response);
    final responseData = json.decode(newresponse.body);
    print("ESTE ES EL TEXTO TRANSCRITO ↓↓↓↓↓↓ ");
    print(responseData["text"]);
    //print("JSON↓");
    /*setState(() {
      if (responseData["text"] != null) {
        _transcripts.add(responseData["text"]);
      } else {
        print("EL AUDIO NO CONTIENE NADA");
      }
    });*/
    //print(json.decode(responseData));
    return responseData["text"]; //Retorna un string
  }

  @override
  void initState() {
    //_grabacionTerminada = false;
    super.initState();
    //record = AudioRecorder();
    /*try {
      record = AudioRecorder();
    } catch (e) {
      // Manejar el error si la creación del AudioRecorder falla
      print("Error al crear AudioRecorder: $e");
    }*/
  }

  void _onRecordButtonPressed() async {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Iniciar la grabación solo si el objeto record no se ha eliminado
      if (await record.isRecording()) {
        return;
      }
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() async {
    final path = await getTemporaryDirectory();
    //final filename = DateTime.now().millisecondsSinceEpoch.toString() + '.wav';
    final filename = '${DateTime.now().millisecondsSinceEpoch}.wav';
    final filePath = path.path + '/' + filename;
    //startStreaming(RecordConfig());
    //NECESITO CREAR UN STREAMING PARA NO DEPENDER DE QUE SE DEBE
    //CANCELAR EL AUDIO PARA LLAMAR LA API

    if (await record.hasPermission()) {
      await record.start(const RecordConfig(), path: filePath);
      /*Timer.periodic(Duration(seconds: 10), (timer) async {
        final path = await record.stop();
        _startRecording();
      });*/
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _stopRecording() async {
    // Detener la grabación de audio

    final path = await record.stop();
    //_sendAudioToServer(path!);
    //_transcribeAudio(path!);
    //convertTextToSpeech(path!);
    convertTextToSpeech(path!);
    /*print(whisper.runtimeType);
    Map<String, String> body = {
      'transcripcion': json.encode(await whisper),
    };
    print("BODY");
    print(body);
    print("FIN DEL BODY");
    print(body.runtimeType);
    print(body['transcripcion']);
    _transcription = body['transcripcion']!;*/
    //print(await whisper);
    //funcion para enviar los resultados de whisper al servidor
    //_enviarWhisperAlServer(whisper);
    //_enviarWhisperAlServer(body);
    //record.dispose();
    //_grabacionTerminada = true;
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    super.dispose();

    // Eliminar el objeto record
    record.dispose();
  }

  Future<void> _sendAudioToServer(audioFile) async {
    // Obtener la ruta del archivo de audio
    //String? audioPath = await audioFile;

    // Crear una solicitud HTTP
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.0.2.2:5000/transcribe'));
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile));
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio enviado correctamente')));
      } else {
        print('Error al enviar audio: ${response.statusCode}');
        // Display an error message to the user
      }
    } catch (e) {
      print('Error en la comunicación con el servidor: $e');
      // Display an error message to the user
    }
  }

  //METODO PARA ENVIAR LA TRANSCRIPCION A FLASK
  Future<void> _enviarWhisperAlServer(Map<String, String> transcripcion) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.0.2.2:5000/transcription'));

      //Añadir la transcripcion en el request de flutter
      print("ENVIAR AL SERVER");
      print(transcripcion);
      print(transcripcion['transcripcion']);
      request.fields['transcription'] = transcripcion['transcripcion']!;
      //String jsonData = json.encode(transcripcion);
      //print("JSONDATA A FLASK");
      //print(jsonData);
      //request.fields['transcription'] = jsonData;

      request.headers.remove('Content-Type');
      request.headers['Content-Type'] = 'application/json; charset=UTF-8';

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio enviado correctamente')));
      } else {
        if (response.statusCode == 201) {
          print("Se debe cambiar el formato a json");
        } else {
          print('Error al enviar audio al server: ${response.statusCode}');
        }
        // Display an error message to the user
      }
    } catch (e) {
      print('Error en la comunicación con el servidor Flask: $e');
      // Display an error message to the user
    }
  }

  Future<void> _transcribeAudio(String audioFile) async {
    // Obtener la ruta del archivo de audio
    //String? audioPath = await audioFile;

    // Crear una solicitud HTTP
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://10.0.2.2:5000/diarization')); //'POST', Uri.parse('http://10.0.2.2:5000/transcription'));
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile));
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio enviado correctamente')));
        var responseBody = await response.stream;
        _transcription = json.decode(responseBody as String)['transcription'];
      } else {
        print('Error al enviar audio: ${response.statusCode}');
        // Display an error message to the user
      }
    } catch (e) {
      print('Error en la comunicación con el servidor: $e');
      // Display an error message to the user
    }
  }

  Future<void> _pruebaServidor(String endpoint) async {
    final url = "http://10.0.2.2:5000"; //10.0.2.2 localhost en Flutter

    var request = http.MultipartRequest("GET", Uri.parse(url));

    var response = await request.send();
    if (response.statusCode == 200) {
      print('Respuesta del servidor: ${await response.stream.bytesToString()}');
    } else {
      print('Error en la solicitud HTTP: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  ElevatedButton(
                    onPressed: () async {
                      await _pruebaServidor("/");
                    },
                    child: Text("Prueba con el servidor"),
                  ),
                  /*  IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _onRecordButtonPressed ,
                ),*/
                  ElevatedButton(
                    onPressed: _isRecording ? null : _startRecording,
                    child: Text('Comenzar a grabar'),
                  ),
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : null,
                    child: Text('Detener grabación'),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _transcripts.length,
                        itemBuilder: (context, index) {
                          return Text(_transcripts[index]);
                        },
                      ),
                    ],
                  ),
                  //Text(_transcription),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Diarization App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<void> _sendAudio(File audio, String endpoint) async {

    final url = "http://10.0.2.2:5000/";
    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..files.add(await http.MultipartFile.fromPath('audio', audio.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      print('Respuesta del servidor: ${await response.stream.bytesToString()}');
    } else {
      print('Error en la solicitud HTTP: ${response.reasonPhrase}');
    }
  }

  Future<void> _sendData(String endpoint) async {

    final url = "http://10.0.2.2:5000";
    //var request = http.MultipartRequest('POST', Uri.parse(url))
      //..files.add(await http.MultipartFile.fromPath('audio', audio.path));

    var request = http.MultipartRequest("GET", Uri.parse(url));

    var response = await request.send();
    if (response.statusCode == 200) {
      print('Respuesta del servidor: ${await response.stream.bytesToString()}');
    } else {
      print('Error en la solicitud HTTP: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Diarization App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                var audioFile1 = File('/audios/audio.wav');
                //print(audioFile1.absolute.path);
                if (await audioFile1.exists()) {
                  // El archivo existe, continúa con la carga
                } else {
                  print('El archivo no existe en la ubicación especificada.');
                }

                var audioFile = File("/audios/audio.wav");
                if (!audioFile.existsSync()) {

                  print("UPLOADING FILE NOT EXIST+++++++++++++++++++++++++++++++++++++++++++++++++");
                  return;
                }
                await _sendAudio(audioFile, 'diarization');
              },
              child: Text('Realizar Diarización'),
            ),
            SizedBox(
              height: 50,
            ),
            ElevatedButton(
              onPressed: () async {

                var audioFile = File("lib/audios/audio.wav");
                //modelos_paper/lib/audios/audio.wav
                if (!audioFile.existsSync()) {
                  print("UPLOADING FILE NOT EXIST+++++++++++++++++++++++++++++++++++++++++++++++++");
                  return;
                }
                await _sendAudio(audioFile, 'transcription');
              },
              child: Text('Realizar Transcripción'),
            ),
              SizedBox(
              height: 50,
            ),
            ElevatedButton(
            onPressed: () async {

            //var audioFile = File("/audios/audio.wav");

            await _sendData('/');
            },
            child: Text('Realizar PRUEBA'),
            ),
            SizedBox(
              height: 50,
            ),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: null, icon: Icon(Icons.mic_none), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
