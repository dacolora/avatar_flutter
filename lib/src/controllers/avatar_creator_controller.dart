import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/avatar_creator_result.dart';
import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';
import '../models/avatar_selection.dart';

/// Controla todo el estado "vivo" del creador de avatar: cuál categoría está
/// activa, qué ha seleccionado el usuario hasta ahora, y el proceso de
/// generar la imagen final al guardar.
///
/// ### ¿Qué es un `ChangeNotifier` y por qué se usa aquí?
/// [ChangeNotifier] es una clase de Flutter pensada para modelar "estado que
/// cambia con el tiempo y que varios widgets necesitan leer". Funciona así:
///
/// 1. El estado (en este caso, [selection], [activeCategoryId], etc.) vive
///    como campos privados de esta clase.
/// 2. Cada método que cambia ese estado (como [selectOption] o
///    [selectCategory]) termina llamando a `notifyListeners()`, un método
///    heredado de [ChangeNotifier] que avisa "algo cambió" a quien esté
///    escuchando.
/// 3. En la UI, [AvatarCreatorScreen] envuelve esta clase con un
///    [AvatarCreatorScope] (un `InheritedNotifier` propio de este paquete,
///    sin depender de paquetes externos como `provider`) y los widgets
///    hijos la leen con `AvatarCreatorScope.of(context)`. Eso hace que el
///    widget se reconstruya automáticamente cada vez que se llama a
///    `notifyListeners()`, sin que tengas que pasar el estado a mano por
///    cada constructor.
///
/// En otras palabras: este controlador es la "fuente de verdad" única, y los
/// widgets (`AvatarPreview`, `AvatarCategoryTabs`, `AvatarOptionGrid`, etc.)
/// simplemente reflejan lo que hay aquí dentro.
///
/// ### Reglas de interacción que este controlador respeta
/// Al tocar una opción, la selección se actualiza de inmediato (sin pedir
/// confirmación) y el preview se redibuja al instante. Cambiar de categoría
/// (tab) **no** borra lo elegido en las demás categorías: cada categoría
/// conserva su propia selección en memoria mientras el usuario navega. Todo
/// ese estado en memoria se pierde solo si el usuario cancela o cierra sin
/// guardar (eso lo maneja [AvatarCreatorScreen], no este controlador).
class AvatarCreatorController extends ChangeNotifier {
  /// [initialSelection] llega ya resuelto (un `Map<String, String>` plano,
  /// no un `Future`): quien construye el controlador —
  /// [AvatarCreatorScreen] — es responsable de esperar el
  /// `Future<Map<String, String>>?` de [AvatarCreatorConfig.initialSelection]
  /// antes de crear esta instancia, ya que un [ChangeNotifier] no tiene
  /// forma natural de representar "todavía estoy cargando mi estado
  /// inicial".
  AvatarCreatorController({
    required List<AvatarLayerCategory> categories,
    Map<String, String>? initialSelection,
  })  : assert(categories.isNotEmpty, 'El catálogo debe tener al menos una categoría'),
        categories = List.unmodifiable(categories),
        _selection = initialSelection != null
            ? AvatarSelection(initialSelection)
            : _defaultSelection(categories),
        _activeCategoryId = categories.first.id;

  /// Construye la selección "de fábrica": la primera opción de cada
  /// categoría. Se usa cuando el canal no proporciona una
  /// [AvatarCreatorConfig.initialSelection] explícita (caso "avatar nuevo").
  static AvatarSelection _defaultSelection(List<AvatarLayerCategory> categories) {
    return AvatarSelection({
      for (final category in categories) category.id: category.options.first.id,
    });
  }

  /// Catálogo de categorías con el que se creó este controlador. Se guarda
  /// envuelto en `List.unmodifiable(...)` para que nadie fuera de esta clase
  /// pueda mutarlo accidentalmente (por ejemplo, agregando o quitando
  /// categorías después de crear el controlador, lo cual dejaría el estado
  /// en un lugar inconsistente).
  final List<AvatarLayerCategory> categories;

  /// `GlobalKey` que [AvatarPreview] asigna a su `RepaintBoundary`. Una
  /// `GlobalKey` es la forma que tiene Flutter de "encontrar" un widget
  /// concreto del árbol desde fuera de él — aquí se usa para, en el momento
  /// de guardar, ubicar exactamente ese `RepaintBoundary` y pedirle que
  /// convierta lo que tiene dibujado en una imagen (ver
  /// [_capturePreviewPng]).
  final GlobalKey previewBoundaryKey = GlobalKey();

  AvatarSelection _selection;

  /// La selección actual (`categoryId -> optionId`) de todas las
  /// categorías, incluida la de color de fondo.
  AvatarSelection get selection => _selection;

  String _activeCategoryId;

  /// Id de la categoría cuyo tab está activo ahora mismo (la que se muestra
  /// con sus opciones debajo de la fila de tabs).
  String get activeCategoryId => _activeCategoryId;

  bool _isSaving = false;

  /// `true` mientras [save] está en progreso (generando la imagen). La UI lo
  /// usa, por ejemplo, para deshabilitar el botón "Guardar" y evitar que el
  /// usuario lo toque dos veces mientras ya hay un guardado en curso.
  bool get isSaving => _isSaving;

  Object? _saveError;

  /// El último error ocurrido al guardar, o `null` si no hay ninguno
  /// pendiente. Se limpia manualmente con [clearSaveError] (por ejemplo,
  /// después de mostrarlo al usuario) o automáticamente al iniciar un nuevo
  /// intento de guardado.
  Object? get saveError => _saveError;

  /// La categoría completa (no solo el id) correspondiente a
  /// [activeCategoryId].
  AvatarLayerCategory get activeCategory => categoryById(_activeCategoryId);

  /// Busca una categoría del catálogo por su id.
  AvatarLayerCategory categoryById(String categoryId) =>
      categories.firstWhere((category) => category.id == categoryId);

  /// Devuelve la opción actualmente seleccionada para [categoryId].
  ///
  /// Si todavía no hay ninguna selección registrada para esa categoría en
  /// [selection] (esto puede pasar si el canal proveyó una
  /// [AvatarCreatorConfig.initialSelection] incompleta), se devuelve
  /// `category.options.first` como valor de respaldo, en vez de lanzar una
  /// excepción.
  AvatarOption selectedOptionFor(String categoryId) {
    final category = categoryById(categoryId);
    final optionId = _selection.selectedOptionFor(categoryId);
    return optionId == null ? category.options.first : category.optionById(optionId);
  }

  /// Rutas de los assets SVG de todas las categorías de tipo
  /// [AvatarCategoryKind.layer], en el mismo orden en que aparecen en
  /// [categories]. [AvatarPreview] recorre esta lista y dibuja cada asset
  /// uno encima del otro (con un `Stack`), así que el orden aquí determina
  /// literalmente qué capa queda "por encima" de cuál en el dibujo final.
  List<String> get layerAssetPaths => [
        for (final category in categories)
          if (category.kind == AvatarCategoryKind.layer)
            selectedOptionFor(category.id).assetPath!,
      ];

  /// Color de fondo actualmente seleccionado (busca la primera categoría de
  /// tipo [AvatarCategoryKind.colorRow] en el catálogo y devuelve su opción
  /// elegida). Si el catálogo no tuviera ninguna categoría de color —algo
  /// que no ocurre con [defaultAvatarCatalog], pero sí podría pasar con un
  /// catálogo personalizado— se usa `Colors.transparent` como respaldo.
  Color get backgroundColor {
    for (final category in categories) {
      if (category.kind == AvatarCategoryKind.colorRow) {
        return selectedOptionFor(category.id).color ?? Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  /// Cambia la categoría activa (es decir, cuál tab está seleccionado) y
  /// notifica a los widgets que dependen de este controlador para que se
  /// redibujen. Si [categoryId] ya es la categoría activa, no hace nada (no
  /// tiene sentido notificar un cambio que en realidad no ocurrió).
  void selectCategory(String categoryId) {
    if (categoryId == _activeCategoryId) return;
    _activeCategoryId = categoryId;
    notifyListeners();
  }

  /// Registra que, dentro de la categoría [categoryId], el usuario eligió la
  /// opción [optionId]. Internamente reemplaza [_selection] por el resultado
  /// de [AvatarSelection.withOption] (recuerda que [AvatarSelection] es
  /// inmutable, así que esto crea una instancia nueva en vez de mutar la
  /// anterior) y notifica a los widgets que escuchan.
  void selectOption(String categoryId, String optionId) {
    _selection = _selection.withOption(categoryId: categoryId, optionId: optionId);
    notifyListeners();
  }

  /// Limpia [saveError]. Útil, por ejemplo, después de que la UI ya mostró
  /// el mensaje de error al usuario y quiere volver al estado "sin error
  /// pendiente".
  void clearSaveError() {
    if (_saveError == null) return;
    _saveError = null;
    notifyListeners();
  }

  /// Convierte lo que está dibujado en el `RepaintBoundary` del preview (ver
  /// [previewBoundaryKey] y [AvatarPreview]) en una imagen PNG.
  ///
  /// Este es el mecanismo que usa Flutter para "capturar como foto" un
  /// widget cualquiera: `previewBoundaryKey.currentContext` te da acceso al
  /// `BuildContext` del widget que tiene esa key (en este caso, el
  /// `RepaintBoundary` de [AvatarPreview]); `findRenderObject()` obtiene el
  /// objeto de bajo nivel que Flutter usa internamente para pintar en
  /// pantalla; y como ese objeto es específicamente un
  /// `RenderRepaintBoundary`, tiene un método `toImage()` que renderiza su
  /// contenido actual a una imagen en memoria (`ui.Image`), sin necesidad de
  /// hacer una captura de pantalla del dispositivo completo.
  ///
  /// `pixelRatio: 3` pide una imagen a 3 píxeles físicos por cada píxel
  /// lógico, para que la imagen final se vea nítida incluso en pantallas de
  /// alta densidad. Después, `toByteData(format: ui.ImageByteFormat.png)`
  /// codifica esa imagen en el formato PNG y `byteData.buffer.asUint8List()`
  /// la convierte en la lista de bytes que el resto del código (y el canal)
  /// puede usar.
  ///
  /// Lanza un [StateError] si el preview todavía no está en pantalla (por
  /// ejemplo, si se llamara a esto antes de que la pantalla termine de
  /// construirse) o si, por algún motivo, no fue posible codificar la
  /// imagen a PNG.
  Future<Uint8List> _capturePreviewPng() async {
    final renderObject = previewBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('El preview del avatar no está disponible para capturar.');
    }
    final ui.Image image = await renderObject.toImage(pixelRatio: 3);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('No fue posible generar la imagen del avatar.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Genera la imagen final y arma el [AvatarCreatorResult] que se le
  /// entrega al canal. Este es el único punto del widget donde se toca "el
  /// mundo exterior" en el sentido de generar un artefacto (la imagen) para
  /// que otro sistema lo use — pero nótese que **no** sube nada a ningún
  /// servidor ni lo guarda en disco: solo devuelve los bytes en memoria. Es
  /// responsabilidad exclusiva del canal decidir qué hacer con ese
  /// resultado (ver [AvatarCreatorResult]).
  ///
  /// Mientras la operación está en curso, [isSaving] es `true` (y se
  /// notifica al empezar y al terminar, para que la UI pueda, por ejemplo,
  /// deshabilitar el botón "Guardar"). Si algo falla, el error queda
  /// disponible en [saveError] (para que la UI pueda mostrar un estado de
  /// error, según la especificación de diseño) y además se vuelve a lanzar
  /// con `rethrow`, para que quien llamó a `save()` (en este caso,
  /// [AvatarCreatorScreen]) decida cómo reaccionar (por ejemplo, mostrando
  /// un `SnackBar`).
  Future<AvatarCreatorResult> save() async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final Uint8List bytes = await _capturePreviewPng();
      return AvatarCreatorResult(selection: _selection.optionByCategory, imageBytes: bytes);
    } catch (error) {
      _saveError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
