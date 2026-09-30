import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pet shop app starts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      PetShopApp(prefs: prefs, onStorageNotice: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Товар'), findsWidgets);
  });
}
