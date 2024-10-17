import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusCheckbox extends Checkbox {
  SyriusCheckbox({
    super.key,
    required Function(bool?) super.onChanged,
    required super.value,
    required BuildContext context,
  }) : super(
          checkColor: Theme.of(context).scaffoldBackgroundColor,
          activeColor: AppColors.znnColor,
        );
}
