import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth_repository.dart';

class UpdatePasswordUseCase {
  UpdatePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(String newPassword) => _repository.updatePassword(newPassword);
}
