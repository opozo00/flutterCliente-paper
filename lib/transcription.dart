import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/*void main() async {
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
  List<String> _transcripts = [];
  final recorder = AudioRecorder();
  bool isRecording = false;
  //http://localhost:3000
  /*IO.Socket socket = IO.io('http://localhost:5000', <String, dynamic>{
    'transports': ['websocket'],
    //'extraHeaders': {'foo':'bar'}
  });*/
  IO.Socket socket = IO.io('http://localhost:5000', <String, dynamic>{
    'transports': ['websocket'],
    //'extraHeaders': {'foo':'bar'}
  });


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
                    onPressed: () => pruebaSocket,
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
                  ElevatedButton(onPressed: isRecording ? detenerGrabacion : iniciarGrabacion, child: Text(isRecording ? 'Detener Grabación' : 'Iniciar Grabación'),),
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

  void pruebaSocket() async {
    socket.connect();
    socket.onConnect((_){
      print("Connection established");
      //socket.emit('message','Este es un mensaje de prueba desde flutter');
      socket.send('Este es un mensaje de prueba desde flutter' as List<String>);
    });
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
      // Mostrar un Snackbar para indicar que la grabación ha comenzado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grabación iniciada'),
        ),
      );
    }
  }

  Future<void> detenerGrabacion() async {
    if(isRecording){
      try{
        var audio = await recorder.stop();
        setState(() {
          isRecording = false;
        });
        socket.emit("audio",audio);
      }catch (e){
        print("Eror: $e");
      }
      // Mostrar un Snackbar para indicar que la grabación ha comenzado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grabación detenida'),
        ),
      );
    }
  }

  void startRecording(BuildContext context) async {
    // ... (código de grabación original)
    // Inicializar la grabación de audio

    if(await recorder.hasPermission()){
      isRecording = true;
      final path = await getTemporaryDirectory();
      //final filename = DateTime.now().millisecondsSinceEpoch.toString() + '.wav';
      final filename = "audioPruebaFinal" + '.wav';
      final filePath = path.path + '/' + filename;

      await recorder.start(const RecordConfig(), path: filePath);
      isRecording = false;
    }

    // Mostrar un Snackbar para indicar que la grabación ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada'),
      ),
    );
  }

   stopRecording() async {
    // ... (código para detener la grabación de audio)
    final audioData = await recorder.stop();
    // Mostrar un Snackbar para indicar que la grabación ha terminado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación finalizada'),
      ),
    );
    return audioData;
  }

/*  void enviarPruebaServer() async {

  }*/

  /*void enviarAudioServer() async {
    // Conectar al servidor WebSocket
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:5000/audio'),
    );
    IO.Socket socket = IO.io('ws://localhost:5000/audio', {
      'transport': ['websocket'],
      //'extraHeaders': {'foo':'bar'}
    });

    // Enviar audio al servidor en fragmentos
    while (true) {
      //final audioData = await recorder.stop();
      final audioData = stopRecording();
      channel.sink.add(audioData);

      // Recibir la transcripción del servidor
      channel.stream.listen((data) {
        // Agregar el nuevo fragmento de transcripción a la lista
        setState(() {
          _transcripts.add(data);
        });
      });
    }
  }*/

  @override
  void initState() {
    super.initState();
    socket.on('audio', (data) {
      print(data);
      setState(() {
        _transcripts.add(data);
      });
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
    // Eliminar el objeto record
    recorder.dispose();
  }
}


