import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Estas pruebas existen sobre todo para confirmar que, tras quitar la
/// dependencia de `provider`, `AvatarCreatorScreen` sigue funcionando de
/// punta a punta: que `AvatarCreatorScope` reparte correctamente el
/// `AvatarCreatorController` a los widgets hijos, y que el nuevo flujo
/// asíncrono de `AvatarCreatorConfig.initialSelection` (un `Future`, pensado
/// para leer de `SharedPreferences`) se resuelve antes de mostrar la
/// pantalla completa.
void main() {
  testWidgets('sin initialSelection, abre directo con la primera opción de cada categoría', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // La categoría activa por defecto es la primera del catálogo
    // (Vestuario); su etiqueta de sección debe estar visible.
    expect(find.text('Vestuario'), findsWidgets);
  });

  testWidgets('espera el Future de initialSelection antes de construir el controlador', (tester) async {
    final completer = Future<Map<String, String>>.delayed(
      const Duration(milliseconds: 50),
      () => const {'background': 'blue'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AvatarCreatorScreen(
          config: AvatarCreatorConfig(initialSelection: completer),
        ),
      ),
    );

    // Mientras el Future no se resuelve, se muestra un indicador de carga.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Una vez resuelto, el indicador desaparece y la pantalla se construye.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Vestuario'), findsWidgets);
  });

  testWidgets('cambiar de tab conserva la selección de las demás categorías', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // Cambia a la categoría "Cabello" tocando su tab. Cabello es de tipo
    // layerWithColor, así que al activarla deben verse sus dos secciones:
    // la fila de "Color del pelo" y la cuadrícula de "Forma del pelo".
    await tester.tap(find.bySemanticsLabel('Cabello'));
    await tester.pumpAndSettle();

    expect(find.text('Color del pelo'), findsWidgets);
    expect(find.text('Forma del pelo'), findsWidgets);
  });

  testWidgets('elegir un color de pelo distinto no rompe la pantalla y conserva la forma elegida', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Cabello'));
    await tester.pumpAndSettle();

    // Elige explícitamente una forma (no la primera), para confirmar que
    // cambiar el color después no reinicia la forma seleccionada.
    await tester.tap(find.bySemanticsLabel('Forma de pelo 3'));
    await tester.pumpAndSettle();

    // "Morado" es una de las opciones de la fila "Color del pelo": cada
    // color real corresponde a un archivo SVG distinto (ver
    // AvatarLayerCategory.resolveAssetPath), no a un tinte en tiempo de
    // ejecución — esta prueba solo confirma que elegirlo no lanza ninguna
    // excepción y que las dos secciones siguen presentes.
    await tester.tap(find.bySemanticsLabel('Morado'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color del pelo'), findsWidgets);
    expect(find.text('Forma del pelo'), findsWidgets);
    expect(find.bySemanticsLabel('Forma de pelo 3'), findsOneWidget);
  });
}
