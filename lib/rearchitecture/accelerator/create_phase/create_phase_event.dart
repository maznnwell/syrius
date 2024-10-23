part of 'create_phase_bloc.dart';

sealed class CreatePhaseEvent {}

class CreatePhase extends CreatePhaseEvent {
  final Hash id;
  final String name;
  final String description;
  final String url;
  final BigInt znnFundsNeeded;
  final BigInt qsrFundsNeeded;

  CreatePhase({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });
}


