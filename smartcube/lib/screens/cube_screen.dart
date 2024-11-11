import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class CubeScreen extends StatefulWidget {
  @override
  _CubeScreenState createState() => _CubeScreenState();
}

class _CubeScreenState extends State<CubeScreen> {
  late Object cubeObject;

  @override
  void initState() {
    super.initState();
    // Load the 3D cube model from assets
    cubeObject = Object(fileName: "assets/cube.obj");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D Cube Viewer'),
      ),
      body: Center(
        child: Container(
          width: 300,
          height: 300,
          child: Cube(
            interactive: true,
            onSceneCreated: (Scene scene) {
              scene.world.add(cubeObject);
              scene.camera.zoom = 10;
            },
          ),
        ),
      ),
    );
  }
}