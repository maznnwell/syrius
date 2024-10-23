part of 'create_project_bloc.dart';

sealed class CreateProjectEvent {}

class CreateProject extends CreateProjectEvent {
  final String name;
  final String description;
  final String url;
  final BigInt znnFundsNeeded;
  final BigInt qsrFundsNeeded;

  CreateProject({
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });
}


