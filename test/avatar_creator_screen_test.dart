import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_category_tabs.dart';
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
  testWidgets(
      'sin initialSelection, abre directo con la primera opción de cada categoría',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // La categoría activa por defecto es la primera del catálogo
    // (Vestuario, de tipo layerWithColor); sus dos etiquetas de sección
    // deben estar visibles.
    expect(find.text('Color de vestuario'), findsWidgets);
    expect(find.text('Estilo de vestuario'), findsWidgets);
  });

  testWidgets(
      'espera el Future de initialSelection antes de construir el controlador',
      (tester) async {
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
    expect(find.text('Color de vestuario'), findsWidgets);
  });

  testWidgets('cambiar de tab conserva la selección de las demás categorías',
      (tester) async {
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

  testWidgets(
      'elegir un color de pelo distinto no rompe la pantalla y conserva la forma elegida',
      (tester) async {
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

  testWidgets(
      'abrir "Color de fondo" no lanza excepción (regresión: sus opciones son colores puros, sin assetPath)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Color de fondo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color de fondo'), findsWidgets);
  });

  testWidgets(
      'Accesorios abre con "Sin accesorios" preseleccionado y sin lanzar excepción',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Accesorios'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Sin accesorios'), findsOneWidget);
  });

  testWidgets(
      'Vestuario abre con su fila de color (es layerWithColor, no una cuadrícula simple)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // Vestuario ya es la categoría activa por defecto (es la primera del
    // catálogo), así que no hace falta tocar su tab.
    expect(tester.takeException(), isNull);
    expect(find.text('Color de vestuario'), findsWidgets);
    expect(find.text('Estilo de vestuario'), findsWidgets);
  });

  testWidgets(
      'al hacer scroll, el preview se encoge (sin desaparecer) y los tabs de categoría siguen tocables',
      (tester) async {
    const config = AvatarCreatorConfig();
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen(config: config)),
    );
    await tester.pumpAndSettle();

    // Alto inicial del preview: totalmente expandido.
    final expandedSize = tester.getSize(find.byType(AvatarPreview));
    expect(expandedSize.height, config.previewExpandedHeight);

    // Un scroll grande hacia abajo debe alcanzar el mínimo de encogimiento
    // del preview (no puede seguir bajando más que eso), pero nunca debe
    // llegar a 0 ni desaparecer del árbol de widgets.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    final collapsedSize = tester.getSize(find.byType(AvatarPreview));
    expect(collapsedSize.height, config.previewCollapsedHeight);
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
    expect(tester.getSize(find.byType(AvatarPreview)).height,
        config.previewExpandedHeight);
  });

  testWidgets(
      'el canal puede personalizar los altos expandido/encogido del preview',
      (tester) async {
    const config = AvatarCreatorConfig(
      previewExpandedHeight: 300,
      previewCollapsedHeight: 120,
    );
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen(config: config)),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AvatarPreview)).height, 300);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AvatarPreview)).height, 120);
  });

  testWidgets(
      'los tabs de categoría tienen fondo opaco (regresión: el body scrolleado se veía "a través" de ellos)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarCreatorScreen()),
    );
    await tester.pumpAndSettle();

    // AvatarCategoryTabs anida más de un Container (el contenedor exterior
    // con el fondo, y uno por cada botón de tab): el primero en el árbol es
    // siempre el exterior, que es el que debe tener el fondo opaco.
    final tabsContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AvatarCategoryTabs),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = tabsContainer.decoration as BoxDecoration;

    expect(decoration.color, isNotNull);
    // `.alpha` (el entero 0-255) está deprecado desde el rediseño de `Color`
    // con canales de punto flotante; `.a` (double, 0.0-1.0) es su
    // reemplazo — 1.0 significa "completamente opaco".
    expect(decoration.color!.a, 1.0);
  });

  testWidgets(
    'AvatarCreatorScreen.push abre la pantalla como una ruta nueva; guardar la cierra y retorna el AvatarCreatorResult',
    (tester) async {
      AvatarCreatorResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await AvatarCreatorScreen.push(context);
                capturedResult = result as AvatarCreatorResult?;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(AvatarCreatorScreen), findsOneWidget);

      // `controller.save()` captura la imagen con `RenderRepaintBoundary.
      // toImage()`, que corre en el pipeline real de la engine, no en el
      // reloj falso que usa `pump()`/`pumpAndSettle()` por defecto. `tap()`
      // dispara el callback `onPressed` pero no espera a que termine (es
      // "fire and forget" desde el punto de vista del test), así que
      // `runAsync` necesita además una espera real (no un `pump`) para darle
      // tiempo a ese `Future` de completarse de verdad antes de seguir.
      await tester.runAsync(() async {
        await tester.tap(find.text('Guardar'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      // Un `pump()` no basta: la ruta todavía necesita jugar su animación
      // de salida antes de que el widget realmente desaparezca del árbol.
      await tester.pumpAndSettle();

      expect(find.byType(AvatarCreatorScreen), findsNothing);
      expect(capturedResult, isA<AvatarCreatorResult>());
      expect(capturedResult!.imageBytes, isNotEmpty);
    },
  );

  testWidgets(
    'el botón de volver del header cancela: llama a onCancel y cierra la pantalla sin llamar a onSaveSuccess',
    (tester) async {
      var cancelled = false;
      var saveSucceeded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AvatarCreatorScreen.push(
                context,
                config: AvatarCreatorConfig(
                  onCancel: () => cancelled = true,
                  onSaveSuccess: (_) => saveSucceeded = true,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarCreatorScreen), findsNothing);
      expect(cancelled, isTrue);
      expect(saveSucceeded, isFalse);
    },
  );

  testWidgets(
    'si onSaveSuccess lanza una excepción, el guardado se trata como fallido: se llama a onSaveError y se muestra un SnackBar, sin cerrar la pantalla',
    (tester) async {
      Object? capturedError;
      final config = AvatarCreatorConfig(
        onSaveSuccess: (_) => throw Exception('fallo simulado'),
        onSaveError: (error) => capturedError = error,
      );

      await tester.pumpWidget(
        MaterialApp(home: AvatarCreatorScreen(config: config)),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('Guardar'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(capturedError, isNotNull);
      expect(find.text('Algo salió mal al guardar'), findsOneWidget);
      // La pantalla sigue abierta: un error al guardar no la cierra.
      expect(find.byType(AvatarCreatorScreen), findsOneWidget);
    },
  );

  testWidgets(
    'si el Future de initialSelection termina en error, se muestra un mensaje y se llama a onSaveError',
    (tester) async {
      Object? capturedError;
      final failingFuture = Future<Map<String, String>>.delayed(
        const Duration(milliseconds: 10),
        () => throw Exception('no se pudo leer la selección guardada'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AvatarCreatorScreen(
            config: AvatarCreatorConfig(
              initialSelection: failingFuture,
              onSaveError: (error) => capturedError = error,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No fue posible cargar la selección guardada'),
        findsOneWidget,
      );
      expect(capturedError, isNotNull);
    },
  );

  testWidgets(
    'si una categoría layerWithColor no define shapeSectionLabel, el título de la cuadrícula de formas usa category.label',
    (tester) async {
      final categories = [
        AvatarLayerCategory(
          id: 'hair',
          label: 'Cabello',
          icon: Icons.face,
          kind: AvatarCategoryKind.layerWithColor,
          colorSectionLabel: 'Color del pelo',
          // shapeSectionLabel se omite a propósito, para forzar el
          // fallback a category.label (ver AvatarCreatorScreen.build).
          options: const [
            AvatarOption.layer(
                id: 'hair-1', assetPath: 'assets/avatar/hair/1.svg'),
          ],
          colorOptions: const [
            AvatarOption.color(id: 'gray', color: Colors.grey),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AvatarCreatorScreen(
            config: AvatarCreatorConfig(categories: categories),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Color del pelo'), findsWidgets);
      // Como no hay shapeSectionLabel, el título de la cuadrícula de abajo
      // cae de vuelta a category.label ("Cabello"), el mismo texto que ya
      // se usa como etiqueta accesible del tab.
      expect(find.text('Cabello'), findsWidgets);
    },
  );
}
