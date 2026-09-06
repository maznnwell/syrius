import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockRecoverSwapFundsBloc
    extends MockBloc<RecoverSwapFundsEvent, RecoverSwapFundsState>
    implements RecoverSwapFundsBloc {}

void main() {
  testWidgets('dispatches a recovery request to the provided bloc', (
    WidgetTester tester,
  ) async {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final MockRecoverSwapFundsBloc bloc = MockRecoverSwapFundsBloc();
    when(() => bloc.state).thenReturn(const RecoverSwapFundsInitial());

    await tester.pumpWidget(
      BlocProvider<RecoverSwapFundsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: RecoverSwapFundsButton(
              htlcId: htlcId.toString(),
              isEnabled: true,
              text: 'Recover',
              loadingText: 'Recovering',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => bloc.add(RecoverSwapFundsRequested(htlcId: htlcId)),
    ).called(1);
  });
}
