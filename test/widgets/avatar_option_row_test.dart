import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_option_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AvatarOptionRow enforces the 5-item spec limit by default', () {
    final tooManyOptions = List.generate(
      6,
      (index) => AvatarOption.color(id: 'color-$index', color: Colors.primaries[index]),
    );

    expect(
      () => AvatarOptionRow(
        options: tooManyOptions,
        selectedOptionId: null,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });

  test('maxOptions permite que el canal suba el limite (ver AvatarCreatorConfig.maxRowOptions)', () {
    final sixOptions = List.generate(
      6,
      (index) => AvatarOption.color(id: 'color-$index', color: Colors.primaries[index]),
    );

    expect(
      () => AvatarOptionRow(
        options: sixOptions,
        selectedOptionId: null,
        maxOptions: 6,
        onSelected: (_) {},
      ),
      returnsNormally,
    );
  });
}
