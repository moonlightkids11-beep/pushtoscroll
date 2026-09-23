import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;
import '../../domain/pose/pose_landmark.dart';
import '../../domain/pose/push_up_state.dart';
import '../../domain/pose/push_up_counter.dart';
import '../../domain/pose/push_up_detector.dart';
import '../../domain/pose/push_up_validator.dart';

class GoogleMlKitPushUpDetector implements PushUpDetector {
  PushUpCounter _counter = PushUpCounter(PushUpValidator());
  
  final _pushUpController = StreamController<int>.broadcast();
  final _stateController = StreamController<PushUpState>.broadcast();
  
  CameraController? _cameraController;
  final mlkit.PoseDetector _poseDetector = mlkit.PoseDetector(
    options: mlkit.PoseDetectorOptions(
      model: mlkit.PoseDetectionModel.base,
      mode: mlkit.PoseDetectionMode.stream,
    )
  );

  bool _isProcessing = false;
  int _pushUps = 0;

  @override
  Stream<int> get pushUpStream => _pushUpController.stream;

  @override
  Stream<PushUpState> get stateStream => _stateController.stream;

  CameraController? get cameraController => _cameraController;

  @override
  Future<void> startDetection() async {
    // The detector is scoped as a reusable dependency. Reset per-session
    // state so its cumulative stream total cannot be interpreted as new reps
    // by a newly created ExerciseController session.
    _counter = PushUpCounter(PushUpValidator());
    _pushUps = 0;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.nv21 
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    
    _cameraController!.startImageStream((image) {
      _processImage(image);
    });
  }

  @override
  Future<void> stopDetection() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    await _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void dispose() {
    stopDetection();
    _poseDetector.close();
    _pushUpController.close();
    _stateController.close();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);
      
      // Avoid counting multiple people
      if (poses.isNotEmpty) {
        final mappedPose = _mapPose(poses.first);
        final isValidRep = _counter.processPose(mappedPose);
        
        _stateController.add(_counter.currentState);

        if (isValidRep) {
          _pushUps++;
          _pushUpController.add(_pushUps);
        }
      }
    } catch (e) {
      // Ignore processing errors
    } finally {
      _isProcessing = false;
    }
  }

  Pose _mapPose(mlkit.Pose mlkitPose) {
    final Map<LandmarkType, PoseLandmark> landmarks = {};

    void mapLandmark(mlkit.PoseLandmarkType mlkitType, LandmarkType type) {
      final lm = mlkitPose.landmarks[mlkitType];
      if (lm != null) {
        landmarks[type] = PoseLandmark(
          type: type,
          x: lm.x,
          y: lm.y,
          z: lm.z,
          likelihood: lm.likelihood,
        );
      }
    }

    mapLandmark(mlkit.PoseLandmarkType.leftShoulder, LandmarkType.leftShoulder);
    mapLandmark(mlkit.PoseLandmarkType.rightShoulder, LandmarkType.rightShoulder);
    mapLandmark(mlkit.PoseLandmarkType.leftElbow, LandmarkType.leftElbow);
    mapLandmark(mlkit.PoseLandmarkType.rightElbow, LandmarkType.rightElbow);
    mapLandmark(mlkit.PoseLandmarkType.leftWrist, LandmarkType.leftWrist);
    mapLandmark(mlkit.PoseLandmarkType.rightWrist, LandmarkType.rightWrist);
    
    return Pose(landmarks);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  mlkit.InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    mlkit.InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = mlkit.InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = mlkit.InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) return null;

    final format = mlkit.InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != mlkit.InputImageFormat.nv21) ||
        (Platform.isIOS && format != mlkit.InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) {
      return null;
    }
    
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return mlkit.InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }
}
