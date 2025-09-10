import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int selectedCameraIndex = 0; // Keep track of which camera is active

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildUI());
  }

  Widget _buildUI() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            SizedBox(
              height: 600,
              width: 600,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (context, child) {
                      final isUnder =
                          (ValueKey(selectedCameraIndex) != child?.key);
                      var tilt = (rotate.value / pi) * 0.002; 
                      tilt *= isUnder ? -1.0 : 1.0;
                      final value = isUnder
                          ? min(rotate.value, pi / 2)
                          : rotate.value;

                      return Transform(
                        transform: Matrix4.rotationY(value)
                          ..setEntry(3, 0, tilt),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                  );
                },
                child: CameraPreview(
                  cameraController!,
                  key: ValueKey<int>(selectedCameraIndex),
                ),
              ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                IconButton(
                  onPressed: _switchCamera,
                  iconSize: 60,
                  icon: const Icon(
                    Icons.switch_camera_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 40),
                // Take Picture Button
                IconButton(
                  onPressed: () async {
                    XFile picture = await cameraController!.takePicture();
                    await Gal.putImage(picture.path);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Picture saved in gallery"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  iconSize: 100,
                  icon: const Icon(Icons.camera, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupCameraController() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _initCamera(selectedCameraIndex);
    }
  }

  void _initCamera(int index) {
    cameraController?.dispose();
    final camera = cameras[index];
    cameraController = CameraController(camera, ResolutionPreset.ultraHigh);

    cameraController
        ?.initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
        })
        .catchError((Object e) {
          debugPrint("Camera init error: $e");
        });
  }

  void _switchCamera() {
    if (cameras.length > 1) {
      setState(() {
        selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
        _initCamera(selectedCameraIndex);
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
