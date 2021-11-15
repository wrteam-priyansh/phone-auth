import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SignInState {}

class SignInInitial extends SignInState {}

class SignInInProgress extends SignInState {}

class SignInFailure extends SignInState {}

class SignInSuccess extends SignInState {}

class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(SignInInitial());

  void signIn() {}
}
