part of 'refresh_project_bloc.dart';

sealed class RefreshProjectEvent {}

class RefreshProject extends RefreshProjectEvent {
  final Hash projectID;

  RefreshProject({required this.projectID});
}