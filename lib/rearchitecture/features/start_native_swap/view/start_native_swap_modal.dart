import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/start_native_swap/bloc/start_native_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/addresses_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/amount_input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/labeled_input_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A modal containing the form used to start a native P2P swap.
class StartNativeSwapModal extends StatelessWidget {
  /// Creates a native-swap modal.
  const StartNativeSwapModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StartNativeSwapBloc>(
      create: (_) => StartNativeSwapBloc(
        accountBlockUtils: AccountBlockUtils(),
        htlcSwapsService: htlcSwapsService!,
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  Token _selectedToken = kZnnCoin;
  String? _selectedSelfAddress = kSelectedAddress;
  bool _isAmountValid = false;

  final TextEditingController _counterpartyAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String get _counterpartyAddress => _counterpartyAddressController.text;

  String? get _counterpartyAddressError =>
      _validateCounterpartyAddress(_counterpartyAddress);

  @override
  void initState() {
    super.initState();
    context.read<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList
            .map((String? address) => address!)
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _counterpartyAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartNativeSwapBloc, StartNativeSwapState>(
      listener: _onStartNativeSwapStateChanged,
      builder: (BuildContext context, StartNativeSwapState swapState) {
        return BaseModal(
          title: context.l10n.p2pSwapStart,
          child: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
            builder: (_, MultipleBalanceState balanceState) =>
                switch (balanceState.status) {
                  MultipleBalanceStatus.failure => SyriusErrorWidget(
                    balanceState.error!,
                  ),
                  MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
                  MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
                  MultipleBalanceStatus.success => _buildContent(
                    context,
                    accountInfo: balanceState.data![_selectedSelfAddress]!,
                    isLoading: swapState is StartNativeSwapLoading,
                  ),
                },
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required AccountInfo accountInfo,
    required bool isLoading,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        kVerticalGap16,
        Row(
          children: <Widget>[
            Expanded(
              child: LabeledInputContainer(
                labelText: context.l10n.p2pSwapYourAddress,
                inputWidget: AddressesDropdown(
                  _selectedSelfAddress,
                  (String? address) => setState(() {
                    _selectedSelfAddress = address;
                  }),
                ),
              ),
            ),
            kHorizontalGap16,
            Expanded(
              child: LabeledInputContainer(
                labelText: context.l10n.p2pSwapCounterpartyAddress,
                helpText: context.l10n.p2pSwapCounterpartyAddressDescription,
                inputWidget: TextField(
                  decoration: InputDecoration(
                    errorText: _counterpartyAddress.isNotEmpty
                        ? _counterpartyAddressError
                        : null,
                    hintText: context.l10n.p2pSwapAddressHint,
                    suffixIcon: PasteContentButton(
                      controller: _counterpartyAddressController,
                    ),
                  ),
                  enabled: !isLoading,
                  controller: _counterpartyAddressController,
                ),
              ),
            ),
          ],
        ),
        kVerticalGap16,
        Row(
          children: <Widget>[
            Expanded(
              child: LabeledInputContainer(
                labelText: context.l10n.p2pSwapYouAreSending,
                inputWidget: Flexible(
                  child: AmountInputField(
                    controller: _amountController,
                    enabled: !isLoading,
                    accountInfo: accountInfo,
                    valuePadding: 10,
                    textColor: Theme.of(context).colorScheme.inverseSurface,
                    initialToken: _selectedToken,
                    hintText: '0.0',
                    onChanged: (Token token, bool isValid) {
                      if (!isLoading) {
                        setState(() {
                          _selectedToken = token;
                          _isAmountValid = isValid;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            kHorizontalGap16,
            Expanded(
              child: ZtsDropdown(
                availableTokens: getTokensWithBalance(accountInfo: accountInfo),
                selectedToken: _selectedToken,
                onChangeCallback: (Token value) {
                  if (_selectedToken != value) {
                    setState(
                      () {
                        _selectedToken = value;
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        kVerticalGap16,
        BulletPointCard(
          bulletPoints: <RichText>[
            RichText(
              text: BulletPointCard.textSpan(
                context.l10n.p2pSwapWaitForCounterparty,
              ),
            ),
            RichText(
              text: BulletPointCard.textSpan(
                '${context.l10n.p2pSwapReclaimFundsPrefix} ',
                children: <TextSpan>[
                  TextSpan(
                    text: context.l10n.p2pSwapHours(
                      kInitialHtlcDuration.inHours,
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  BulletPointCard.textSpan(
                    ' ${context.l10n.p2pSwapReclaimFundsSuffix}',
                  ),
                ],
              ),
            ),
            RichText(
              text: BulletPointCard.textSpan(
                context.l10n.p2pSwapMachineOnly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStartSwapButton(context, isLoading: isLoading),
      ],
    );
  }

  Widget _buildStartSwapButton(
    BuildContext context, {
    required bool isLoading,
  }) {
    return InstructionButton(
      text: context.l10n.p2pSwapStart,
      instructionText: context.l10n.p2pSwapFillDetails,
      loadingText: context.l10n.p2pSwapSendingTransaction,
      isEnabled: _isInputValid(),
      isLoading: isLoading,
      onPressed: () => _onStartButtonPressed(context),
    );
  }

  void _onStartButtonPressed(BuildContext context) {
    context.read<StartNativeSwapBloc>().add(
      StartNativeSwapRequested(
        selfAddress: Address.parse(_selectedSelfAddress!),
        counterpartyAddress: Address.parse(_counterpartyAddressController.text),
        fromToken: _selectedToken,
        fromAmount: _amountController.text.extractDecimals(
          _selectedToken.decimals,
        ),
        hashType: htlcHashTypeSha3,
        swapType: P2pSwapType.native,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        initialHtlcDuration: kInitialHtlcDuration.inSeconds,
      ),
    );
  }

  void _onStartNativeSwapStateChanged(
    BuildContext context,
    StartNativeSwapState state,
  ) {
    if (state is StartNativeSwapDone) {
      Navigator.pop(context, state.swap.id);
    } else if (state is StartNativeSwapFailure) {
      ToastUtils.showToast(context, state.exception.toString());
    }
  }

  bool _isInputValid() => _counterpartyAddressError == null && _isAmountValid;

  String? _validateCounterpartyAddress(String? address) {
    final String? result = InputValidators.checkAddress(address);
    if (result != null) {
      return result;
    } else {
      return kDefaultAddressList.contains(address)
          ? context.l10n.p2pSwapOwnAddressError
          : null;
    }
  }
}
