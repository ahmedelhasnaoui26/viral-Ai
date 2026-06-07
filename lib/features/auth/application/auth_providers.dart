import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../data/auth_repository_impl.dart';
import '../data/supabase_auth_datasource.dart';
import '../domain/auth_repository.dart';
import 'guest_mode_provider.dart';
import 'usecases/send_password_reset_usecase.dart';
import 'usecases/sign_in_with_email_usecase.dart';
import 'usecases/sign_up_with_email_usecase.dart';
import 'usecases/update_password_usecase.dart';

/// Back-compat alias used across the app.
typedef AuthService = AuthRepository;

final authDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
});

final authServiceProvider = authRepositoryProvider;

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  return SignUpWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((ref) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  return UpdatePasswordUseCase(ref.watch(authRepositoryProvider));
});

final authSessionProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final initial = auth.currentUser;
  return auth.authStateChanges
      .map((event) => event.session?.user)
      .startWith(initial);
});

/// Emits auth events for password recovery routing.
final authChangeEventProvider = StreamProvider<AuthChangeEvent>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .map((state) => state.event);
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    return _auth.currentUser;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    await _auth.signInWithGoogle();
    state = AsyncData(_auth.currentUser);
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    await _auth.signInWithApple();
    state = AsyncData(_auth.currentUser);
  }

  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    late final User user;
    state = await AsyncValue.guard(() async {
      user = await ref.read(signInWithEmailUseCaseProvider).call(
            email: email,
            password: password,
          );
      return user;
    });
    if (state.hasError) throw state.error!;
    return user;
  }

  Future<SignUpResult> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    late final SignUpResult result;
    state = await AsyncValue.guard(() async {
      result = await ref.read(signUpWithEmailUseCaseProvider).call(
            username: username,
            email: email,
            password: password,
          );
      return result.user;
    });
    if (state.hasError) throw state.error!;
    return result;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await ref.read(sendPasswordResetUseCaseProvider).call(email);
  }

  Future<User> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    late final User user;
    state = await AsyncValue.guard(() async {
      user = await ref.read(updatePasswordUseCaseProvider).call(newPassword);
      return user;
    });
    if (state.hasError) throw state.error!;
    return user;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
      return null;
    });
    await ref.read(guestModeProvider.notifier).enterGuestMode(trackAnalytics: false);
  }
}

extension _StartWithAuthStream<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
