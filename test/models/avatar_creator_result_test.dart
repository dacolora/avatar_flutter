import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imageProvider envuelve imageBytes en un MemoryImage', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = AvatarCreatorResult(selection: const {}, imageBytes: bytes);

    expect(result.imageProvider, isA<MemoryImage>());
    expect((result.imageProvider as MemoryImage).bytes, same(bytes));
  });

  test('dos llamadas a imageProvider son == entre si (mismo Uint8List subyacente)', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = AvatarCreatorResult(selection: const {}, imageBytes: bytes);

    expect(result.imageProvider, result.imageProvider);
  });
}
