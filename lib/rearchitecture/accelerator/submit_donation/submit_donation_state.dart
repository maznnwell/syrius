part of 'submit_donation_bloc.dart';

sealed class SubmitDonationState {}

class SubmitDonationInitial extends SubmitDonationState {}

class SubmitDonationInProgress extends SubmitDonationState {}

class SubmitDonationSuccess extends SubmitDonationState {
  final AccountBlockTemplate response;

  SubmitDonationSuccess(this.response);
}

class SubmitDonationFailure extends SubmitDonationState {
  final Object error;

  SubmitDonationFailure(this.error);
}