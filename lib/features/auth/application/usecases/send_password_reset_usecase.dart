import '../../domain/auth_repository.dart';

class SendPasswordResetUseCase {
  SendPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendPasswordResetEmail(email);
}
