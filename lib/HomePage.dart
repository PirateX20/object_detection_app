import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController cameraController;
  late CameraImage imgCamera;
  late bool isReady = false;
  late double frameHeight;
  late double frameWidth;
  late List recognitionsList;

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((imageFromStream) => {
              if (!isReady)
                {
                  imgCamera = imageFromStream,
                  isReady = true,
                  runModelOnStreamFrame(),
                }
            }); //cameraController.startImageStream
      }); //setState
    }); //cameraController.initialize().then
  } //initCamera

  runModelOnStreamFrame() async {
    frameHeight = imgCamera.height + 0.0;
    frameWidth = imgCamera.width + 0.0;
    recognitionsList = (await Tflite.detectObjectOnFrame(
        bytesList: imgCamera.planes.map((Plane) {
          return Plane.bytes;
        }).toList(),
        model: "SSDMobileNet",
        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 1,
        threshold: 0.4))!;

    isReady = false;
    setState(() {
      imgCamera;
    });
  }

  Future loadModel() async {
    Tflite.close();

    try {
      String? response;
      response = await Tflite.loadModel(
          model: "assets/ssd_mobilenet.tflite",
          labels: "assets/ssd_mobilenet.txt");
      print(response);
    } on PlatformException {
      print("ERRO: A aplicação não conseguiu carregar os modelos");
    }
  }

  @override
  void dispose() {
    super.dispose();

    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  List<Widget> objectDisplayBox(Size screen) {
    if (recognitionsList == null) {
      return [];
    }
    if (frameHeight == null || frameWidth == null) {
      return [];
    }
    double valX = screen.width;
    double valY = frameHeight;

    Color corEscolhida = Colors.red;

    return recognitionsList.map((result) {
      return Positioned(
          left: result["rect"]["x"] * valX,
          top: result["rect"]["y"] * valY,
          width: result["rect"]["w"] * valX,
          height: result["rect"]["h"] * valY,
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(color: Colors.red, width: 2.0),
              ),
              child: Text(
                "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  background: Paint()..color = corEscolhida,
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              )));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildrenWidgets = [];
    stackChildrenWidgets.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: Container(
          height: size.height - 100,
          child: (!cameraController.value.isInitialized)
              ? new Container()
              : AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
        )));

    if (imgCamera != null) {
      stackChildrenWidgets.addAll(objectDisplayBox(size));
    }

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.blueGrey,
          body: Container(
            margin: EdgeInsets.only(top: 50),
            color: Colors.blueGrey,
            child: Stack(children: stackChildrenWidgets),
          )),
    );
  }
}
