import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'package:camera/camera.dart';

/*NOTES: {
}*/

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detecção de Objetos em Flutter',
      home: HomePage(),
    );
  }
}
