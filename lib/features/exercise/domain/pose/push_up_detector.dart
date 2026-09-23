import 'push_up_state.dart';

abstract class PushUpDetector {
  Stream<int> get pushUpStream;
  Stream<PushUpState> get stateStream;
  
  Future<void> startDetection();
  Future<void> stopDetection();
  void dispose();
}
