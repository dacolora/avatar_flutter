import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_selectable_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'con un size explícito, la miniatura usa un SizedBox de ese tamaño en vez de AspectRatio(1)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarSelectableThumbnail(
              option: AvatarOption.color(id: 'red', color: Colors.red),
              isSelected: false,
              onTap: () {},
              size: 40,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(AvatarSelectableThumbnail),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
      expect(find.byType(AspectRatio), findsNothing);
    },
  );
}
