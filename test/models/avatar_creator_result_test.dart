import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// PNG de prueba: un cuadrado de `size`x`size`, con la mitad izquierda de
/// un color sólido y opaco y la mitad derecha completamente transparente
/// (simula las esquinas transparentes que deja el `ClipOval` fuera del
/// círculo del avatar real).
Uint8List _fakeAvatarPng({int size = 8}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final color = x < size ~/ 2
          ? img.ColorRgba8(10, 20, 200, 255) // mitad izquierda: azul opaco
          : img.ColorRgba8(0, 0, 0, 0); // mitad derecha: transparente
      image.setPixel(x, y, color);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('imageProvider envuelve imageBytes en un MemoryImage', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = AvatarCreatorResult(selection: const {}, imageBytes: bytes);

    expect(result.imageProvider, isA<MemoryImage>());
    expect((result.imageProvider as MemoryImage).bytes, same(bytes));
  });

  test(
      'dos llamadas a imageProvider son == entre si (mismo Uint8List subyacente)',
      () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = AvatarCreatorResult(selection: const {}, imageBytes: bytes);

    expect(result.imageProvider, result.imageProvider);
  });

  test('toJpg devuelve un JPG válido con las mismas dimensiones del PNG',
      () async {
    final result = AvatarCreatorResult(
        selection: const {}, imageBytes: _fakeAvatarPng(size: 8));

    final jpgBytes = await result.toJpg();
    final decoded = img.decodeJpg(jpgBytes);

    expect(decoded, isNotNull);
    expect(decoded!.width, 8);
    expect(decoded.height, 8);
  });

  test('toJpg aplana las zonas transparentes sobre backgroundColor', () async {
    final result = AvatarCreatorResult(
        selection: const {}, imageBytes: _fakeAvatarPng(size: 8));

    final jpgBytes = await result.toJpg(
      backgroundColor: const Color(0xFFFFFFFF),
      quality: 100,
    );
    final decoded = img.decodeJpg(jpgBytes)!;

    // La mitad derecha era transparente en el PNG original: en el JPG debe
    // quedar cerca de blanco (backgroundColor), no negro.
    final pixel = decoded.getPixel(7, 4);
    expect(pixel.r, greaterThan(240));
    expect(pixel.g, greaterThan(240));
    expect(pixel.b, greaterThan(240));
  });

  test('toJpg preserva el color opaco original (sin transparencia)', () async {
    final result = AvatarCreatorResult(
        selection: const {}, imageBytes: _fakeAvatarPng(size: 8));

    final jpgBytes = await result.toJpg(quality: 100);
    final decoded = img.decodeJpg(jpgBytes)!;

    // La mitad izquierda era azul opaco (10, 20, 200): debe seguir
    // pareciéndose a ese color (con algo de tolerancia por la compresión
    // JPG, que es lossy).
    final pixel = decoded.getPixel(0, 4);
    expect(pixel.r, lessThan(60));
    expect(pixel.b, greaterThan(150));
  });
}
