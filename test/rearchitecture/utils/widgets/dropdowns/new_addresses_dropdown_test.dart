import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/dropdowns/new_addresses_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

void main() {
  const String firstAddress = 'address-1';
  const String secondAddress = 'address-2';

  setUp(() {
    kAddressLabelMap = <String, String>{
      firstAddress: 'Address 1',
      secondAddress: 'Address 2',
    };
  });

  testWidgets('restores the selected label after focus is lost', (
    WidgetTester tester,
  ) async {
    String? selectedAddress;

    await tester.pumpWidget(
      _TestApp(
        onSelected: (String address) => selectedAddress = address,
        selectedAddress: firstAddress,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'invalid filter');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(_fieldText(tester), 'Address 1');
    expect(selectedAddress, isNull);
  });

  testWidgets('restores the label of the latest menu selection', (
    WidgetTester tester,
  ) async {
    String? selectedAddress;

    await tester.pumpWidget(
      _TestApp(
        onSelected: (String address) => selectedAddress = address,
        selectedAddress: firstAddress,
      ),
    );
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Address 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'another filter');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(selectedAddress, secondAddress);
    expect(_fieldText(tester), 'Address 2');
  });
}

String _fieldText(WidgetTester tester) {
  final EditableText field = tester.widget<EditableText>(
    find.byType(EditableText),
  );
  return field.controller.text;
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.onSelected,
    required this.selectedAddress,
  });

  final ValueChanged<String> onSelected;
  final String selectedAddress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: NewAddressesDropdown(
              addresses: const <String>['address-1', 'address-2'],
              onSelectedCallback: onSelected,
              selectedAddress: selectedAddress,
            ),
          ),
        ),
      ),
    );
  }
}
