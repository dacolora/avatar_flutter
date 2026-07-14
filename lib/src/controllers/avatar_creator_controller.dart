import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/avatar_creator_result.dart';
import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';
import '../models/avatar_selection.dart';

/// Controla el estado del creador de avatar: categoría activa, selección en
/// memoria, captura de la imagen final y manejo de errores de guardado.
///
/// Sigue la especificación de interacción: al tocar una opción se actualiza
/// de inmediato (sin confirmación) y el estado de cada categoría se conserva
/// mientras el usuario navega entre tabs; solo se pierde al cancelar/cerrar
/// sin guardar.
class AvatarCreatorController extends ChangeNotifier {
  AvatarCreatorController({
    required List<AvatarLayerCategory> categories,
    AvatarSelection? initialSelection,
  })  : assert(categories.isNotEmpty, 'El catálogo debe tener al menos una categoría'),
        categories = List.unmodifiable(categories),
        _selection = initialSelection ?? _defaultSelection(categories),
        _activeCategoryId = categories.first.id;

  static AvatarSelection _defaultSelection(List<AvatarLayerCategory> categories) {
    return AvatarSelection({
      for (final category in categories) category.id: category.options.first.id,
    });
  }

  final List<AvatarLayerCategory> categories;

  final GlobalKey previewBoundaryKey = GlobalKey();

  AvatarSelection _selection;
  AvatarSelection get selection => _selection;

  String _activeCategoryId;
  String get activeCategoryId => _activeCategoryId;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Object? _saveError;
  Object? get saveError => _saveError;

  AvatarLayerCategory get activeCategory => categoryById(_activeCategoryId);

  AvatarLayerCategory categoryById(String categoryId) =>
      categories.firstWhere((category) => category.id == categoryId);

  /// Opción actualmente seleccionada para [categoryId], o la primera opción
  /// de la categoría si aún no hay selección registrada.
  AvatarOption selectedOptionFor(String categoryId) {
    final category = categoryById(categoryId);
    final optionId = _selection.selectedOptionFor(categoryId);
    return optionId == null ? category.options.first : category.optionById(optionId);
  }

  /// Rutas de los assets de capa a apilar en el preview, en orden de
  /// renderizado (mismo orden del catálogo).
  List<String> get layerAssetPaths => [
        for (final category in categories)
          if (category.kind == AvatarCategoryKind.layer)
            selectedOptionFor(category.id).assetPath!,
      ];

  Color get backgroundColor {
    for (final category in categories) {
      if (category.kind == AvatarCategoryKind.colorRow) {
        return selectedOptionFor(category.id).color ?? Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  void selectCategory(String categoryId) {
    if (categoryId == _activeCategoryId) return;
    _activeCategoryId = categoryId;
    notifyListeners();
  }

  void selectOption(String categoryId, String optionId) {
    _selection = _selection.withOption(categoryId: categoryId, optionId: optionId);
    notifyListeners();
  }

  void clearSaveError() {
    if (_saveError == null) return;
    _saveError = null;
    notifyListeners();
  }

  /// Captura el `RepaintBoundary` del preview y lo devuelve como PNG.
  /// Lanza si el widget de preview aún no está montado.
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

  /// Genera la imagen final y arma el [AvatarCreatorResult] a devolver al
  /// canal. En caso de fallo, deja el estado de error disponible en
  /// [saveError] (ver especificación de "Estados": toast de error) y
  /// relanza la excepción para que quien llame decida cómo reaccionar.
  Future<AvatarCreatorResult> save() async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final Uint8List bytes = await _capturePreviewPng();
      return AvatarCreatorResult(selection: _selection, imageBytes: bytes);
    } catch (error) {
      _saveError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
