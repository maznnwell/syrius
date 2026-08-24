import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/start_native_swap/bloc/start_native_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A modal containing the form used to start a native P2P swap.
class StartNativeSwapModal extends StatelessWidget {
  /// Creates a native-swap modal.
  const StartNativeSwapModal({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ValueNotifier<Token> _tokenNotifier = .new(kZnnCoin);

  Token get _token => _tokenNotifier.value;

  final ValueNotifier<String> _sender = .new(kSelectedAddress!);

  final TextEditingController _counterpartyAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String get _amount => _amountController.text;

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
                balances: balanceState.data!,
              ),
            },
      ),
    );
  }

  Widget _buildContent(
{
    required Map<String, AccountInfo> balances,
  }) {
    return BlocConsumer<StartNativeSwapBloc, StartNativeSwapState>(
      listener: _onStartNativeSwapStateChanged,
      builder: (BuildContext context, StartNativeSwapState swapState) {
        final bool isLoading = swapState is StartNativeSwapLoading;

        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable?>[
            _amountController,
            _sender,
            _tokenNotifier,
          ]),
          builder: (_, _) {
            final AccountInfo accountInfo = balances[_sender.value]!;

            final String? amountError = _amount.isNotEmpty
                ? InputValidators.correctValue(
              _amount,
              accountInfo.getBalance(
                _token.tokenStandard,
              ),
              _token.decimals,
              BigInt.zero,
            )
                : null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: kVerticalGap16.height!,
              children: <Widget>[
                kVerticalGap16,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: NewAddressesDropdown(
                        addresses: kDefaultAddressList
                            .map((String? e) => e!)
                            .toList(),
                        label: Text(context.l10n.p2pSwapYourAddress),
                        selectedAddress: _sender,
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          errorText: _counterpartyAddress.isNotEmpty
                              ? _counterpartyAddressError
                              : null,
                          hintText: context.l10n.p2pSwapAddressHint,
                          labelText: context.l10n.p2pSwapCounterpartyAddress,
                          suffixIcon: PasteContentButton(
                            controller: _counterpartyAddressController,
                          ),
                        ),
                        enabled: !isLoading,
                        controller: _counterpartyAddressController,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AmountTextField(
                        accountInfo: accountInfo,
                        controller: _amountController,
                        errorText: amountError,
                        labelText: context.l10n.p2pSwapYouAreSending,
                        token: _token,
                        onSubmitted: (_) {},
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: ZtsDropdown(
                        availableTokens: getTokensWithBalance(
                          accountInfo: accountInfo,
                        ),
                        label: Text(context.l10n.asset),
                        selectedToken: _tokenNotifier,
                      ),
                    ),
                  ],
                ),
                BulletPointCard(
                  bulletPoints: <String>[
                    context.l10n.p2pSwapWaitForCounterparty,
                    context.l10n.p2pSwapReclaimFunds(
                      context.l10n.p2pSwapHours(
                        kInitialHtlcDuration.inHours,
                      ),
                    ),
                    context.l10n.p2pSwapMachineOnly,
                  ],
                ),
                _buildStartSwapButton(context, isLoading: isLoading),
              ],
            );
          },
        );
      },
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
        selfAddress: Address.parse(_sender.value),
        counterpartyAddress: Address.parse(_counterpartyAddressController.text),
        fromToken: _token,
        fromAmount: _amountController.text.extractDecimals(
          _token.decimals,
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
      Navigator.pop(context);
    }
  }

  bool _isInputValid() => _counterpartyAddressError == null;

  String? _validateCounterpartyAddress(String? address) {
    final String? result = InputValidators.checkAddress(address);
    if (result != null) {
      return result;
    } else {
      // TODO: bug, the user can manually generate addresses and bypass check
      return kDefaultAddressList.contains(address)
          ? context.l10n.p2pSwapOwnAddressError
          : null;
    }
  }
}
