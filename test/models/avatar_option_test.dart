import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // AvatarOption extiende Equatable para que dos instancias con los mismos
  // valores se consideren iguales por contenido, no por identidad de objeto
  // (ver el comentario de la clase). Estas pruebas construyen las opciones
  // sin `const` a propósito: con `const`, Dart canonicalizaría ambas
  // instancias en el mismo objeto en memoria, y `==` pasaría igual aunque
  // Equatable no hiciera nada — así se confirma que la comparación funciona
  // por contenido de verdad.
  test('dos AvatarOption.layer con los mismos valores son iguales', () {
    final a = AvatarOption.layer(id: 'face-1', assetPath: 'assets/face-1.svg');
    final b = AvatarOption.layer(id: 'face-1', assetPath: 'assets/face-1.svg');

    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('dos AvatarOption con algún valor distinto no son iguales', () {
    final a = AvatarOption.layer(id: 'face-1', assetPath: 'assets/face-1.svg');
    final b = AvatarOption.layer(id: 'face-1', assetPath: 'assets/face-2.svg');

    expect(a, isNot(b));
  });

  test('dos AvatarOption.color con el mismo color son iguales', () {
    final a = AvatarOption.color(id: 'green', color: Colors.green);
    final b = AvatarOption.color(id: 'green', color: Colors.green);

    expect(a, b);
  });

  test(
      'AvatarOption.none con thumbnailAssetPath sigue sin assetPath (no aporta capa al preview)',
      () {
    const option = AvatarOption.none(
      id: 'none',
      semanticLabel: 'Sin pelo',
      thumbnailAssetPath: 'assets/avatar/hair/none.svg',
      assetPackage: 'avatar_flutter',
    );

    expect(option.isNone, isTrue);
    expect(option.assetPath, isNull);
    expect(option.thumbnailAssetPath, 'assets/avatar/hair/none.svg');
  });
}
