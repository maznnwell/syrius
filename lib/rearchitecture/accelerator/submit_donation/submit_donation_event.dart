part of 'submit_donation_bloc.dart';

sealed class SubmitDonationEvent {}

class SubmitDonation extends SubmitDonationEvent {
  final BigInt znnAmount;
  final BigInt qsrAmount;

  SubmitDonation({
    required this.znnAmount,
    required this.qsrAmount,
  });
}