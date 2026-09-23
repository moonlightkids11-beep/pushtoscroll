import '../time_repository.dart';

class GetRemainingTimeUseCase {
  final TimeRepository _timeRepository;

  GetRemainingTimeUseCase(this._timeRepository);

  Future<int> execute() async {
    return await _timeRepository.getAvailableTime();
  }
}
