import 'package:avatar_flutter/src/models/avatar_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // AvatarSelection es un detalle interno de AvatarCreatorController (no se
  // exporta desde avatar_flutter.dart), por eso se importa directamente
  // desde src/ — el mismo patrón que ya usan las pruebas de
  // avatar_creator_screen_test.dart para los widgets internos.
  test('dos AvatarSelection con el mismo mapa son iguales gracias a Equatable',
      () {
    final a = AvatarSelection({'hair': 'hair-1'});
    final b = AvatarSelection({'hair': 'hair-1'});

    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('dos AvatarSelection con mapas distintos no son iguales', () {
    final a = AvatarSelection({'hair': 'hair-1'});
    final b = AvatarSelection({'hair': 'hair-2'});

    expect(a, isNot(b));
  });
}
