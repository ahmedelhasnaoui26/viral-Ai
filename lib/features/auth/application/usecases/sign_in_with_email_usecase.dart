import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth_repository.dart';

class SignInWithEmailUseCase {
  SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String email, required String password}) =>
      _repository.signInWithEmailPassword(email: email, password: password);
}
