part of 'update_phase_bloc.dart';

sealed class UpdatePhaseEvent {}

class UpdatePhase extends UpdatePhaseEvent {
  final Hash id;
  final String name;
  final String description;
  final String url;
  final BigInt znnFundsNeeded;
  final BigInt qsrFundsNeeded;

  UpdatePhase({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });
}


