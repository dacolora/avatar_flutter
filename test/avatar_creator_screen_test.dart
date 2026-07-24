import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_preview.dart';
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
    // cambiar el color después no reinicia la forma elegida. El body (a
    // diferencia del preview y los tabs) es la parte que de verdad se
    // desplaza con el scroll, así que primero hay que asegurarse de que la
    // opción esté a la vista antes de tocarla.
    final shape3 = find.bySemanticsLabel('Forma de pelo 3');
    await tester.ensureVisible(shape3);
    await tester.pumpAndSettle();
    await tester.tap(shape3);
    await tester.pumpAndSettle();

    // "Morado" es una de las opciones de la fila "Color del pelo": cada
    // color real corresponde a un archivo SVG distinto (ver
    // AvatarLayerCategory.resolveAssetPath), no a un tinte en tiempo de
    // ejecución — esta prueba solo confirma que elegirlo no lanza ninguna
    // excepción y que las dos secciones siguen presentes.
    final purple = find.bySemanticsLabel('Morado');
    await tester.ensureVisible(purple);
    await tester.pumpAndSettle();
    await tester.tap(purple);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color del pelo'), findsWidgets);
    expect(find.text('Forma del pelo'), findsWidgets);
    expect(find.bySemanticsLabel('Forma de pelo 3'), findsOneWidget);
  });

  testWidgets('abrir "Color de fondo" no lanza excepción (regresión: sus opciones son colores puros, sin assetPath)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Color de fondo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color de fondo'), findsWidgets);
  });

  testWidgets('Accesorios abre con "Sin accesorios" preseleccionado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Accesorios'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Sin accesorios'), findsOneWidget);
  });

  testWidgets('al hacer scroll, el preview se encoge (sin desaparecer) y los tabs de categoría siguen tocables', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // Alto inicial del preview: totalmente expandido.
    final expandedSize = tester.getSize(find.byType(AvatarPreview));
    expect(expandedSize.height, AvatarPreview.expandedHeight);

    // Un scroll grande hacia abajo debe alcanzar el mínimo de encogimiento
    // del preview (no puede seguir bajando más que eso), pero nunca debe
    // llegar a 0 ni desaparecer del árbol de widgets.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    final collapsedSize = tester.getSize(find.byType(AvatarPreview));
    expect(collapsedSize.height, AvatarPreview.collapsedHeight);
    expect(find.byType(AvatarPreview), findsOneWidget);

    // Los tabs de categoría siguen debajo del preview y se pueden seguir
    // tocando aunque el body esté scrolleado.
    await tester.tap(find.bySemanticsLabel('Cabello'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Color del pelo'), findsWidgets);

    // Al volver a subir el scroll, el preview se expande de nuevo.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AvatarPreview)).height, AvatarPreview.expandedHeight);
  });
}
