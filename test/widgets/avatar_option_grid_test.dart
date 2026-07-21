import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_option_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AvatarOptionGrid reports the tapped option id', (tester) async {
    const options = [
      AvatarOption.color(id: 'green', color: Colors.green, semanticLabel: 'Verde'),
      AvatarOption.color(id: 'blue', color: Colors.blue, semanticLabel: 'Azul'),
    ];

    String? selectedOptionId = 'green';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AvatarOptionGrid(
                options: options,
                selectedOptionId: selectedOptionId,
                onSelected: (optionId) => setState(() => selectedOptionId = optionId),
              ),
            );
          },
        ),
      ),
    );

    expect(find.bySemanticsLabel('Verde'), findsOneWidget);
    expect(find.bySemanticsLabel('Azul'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Azul'));
    await tester.pumpAndSettle();

    expect(selectedOptionId, 'blue');
  });

  testWidgets('AvatarOptionGrid tints every thumbnail with the given color', (tester) async {
    const options = [
      AvatarOption.layer(id: 'hair-1', assetPath: 'assets/avatar/hair/hair_1.svg'),
      AvatarOption.layer(id: 'hair-2', assetPath: 'assets/avatar/hair/hair_1.svg'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarOptionGrid(
            options: options,
            selectedOptionId: 'hair-1',
            tint: Colors.purple,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final svgPictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(svgPictures, hasLength(2));
    for (final svgPicture in svgPictures) {
      expect(svgPicture.colorFilter, const ColorFilter.mode(Colors.purple, BlendMode.srcIn));
    }
  });

  testWidgets('AvatarOptionGrid enforces the 10-item spec limit', (tester) async {
    final tooManyOptions = List.generate(
      11,
      (index) => AvatarOption.layer(id: 'body-$index', assetPath: 'assets/avatar/body/body_1.svg'),
    );

    expect(
      () => AvatarOptionGrid(
        options: tooManyOptions,
        selectedOptionId: null,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
