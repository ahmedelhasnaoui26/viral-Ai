import '../../domain/auth_repository.dart';

class SignUpWithEmailUseCase {
  SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<SignUpResult> call({
    required String username,
    required String email,
    required String password,
  }) =>
      _repository.signUpWithEmailPassword(
        username: username,
        email: email,
        password: password,
      );
}
