import '../time_repository.dart';

class ConsumeTimeUseCase {
  final TimeRepository _timeRepository;

  ConsumeTimeUseCase(this._timeRepository);

  Future<void> execute(int seconds) async {
    if (seconds <= 0) return;
    await _timeRepository.consumeTime(seconds);
  }
}
