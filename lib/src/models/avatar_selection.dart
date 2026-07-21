import 'package:equatable/equatable.dart';

/// Foto instantánea (snapshot) e **inmutable** de la selección actual del
/// usuario: qué opción está elegida en cada categoría.
///
/// Internamente es solo un mapa `categoryId -> optionId` (por ejemplo,
/// `{'face': 'face-3', 'hair': 'hair-1', 'background': 'green'}`). Nota que
/// la categoría de color de fondo se guarda igual que cualquier otra: para
/// este modelo no hay diferencia entre "una capa ilustrada seleccionada" y
/// "un color seleccionado", ambas son simplemente "la opción elegida para
/// esta categoría".
///
/// ### ¿Por qué es inmutable?
/// [AvatarSelection] no tiene ningún método que modifique
/// [optionByCategory] en el sitio (no hay un `selection.setOption(...)` que
/// cambie el mapa existente). En cambio, [withOption] siempre devuelve una
/// instancia **nueva**. Este patrón ("copiar con un cambio") es muy común
/// en Flutter porque encaja con cómo funciona la reconstrucción de widgets:
/// en vez de mutar un objeto compartido (lo cual puede generar bugs difíciles
/// de rastrear si dos partes del código tienen una referencia al mismo
/// objeto y una lo cambia sin que la otra se entere), cada cambio produce un
/// objeto distinto, y quien lo escucha ([AvatarCreatorController] mediante
/// `ChangeNotifier`) decide cuándo notificar que "hay un valor nuevo".
///
/// ### ¿Por qué extiende [Equatable]?
/// Igual que en [AvatarOption], para que dos [AvatarSelection] con el mismo
/// contenido se consideren iguales con `==`, en vez de compararse por
/// identidad de objeto. Esto es lo que permite, por ejemplo, escribir tests
/// como `expect(controller.selection, const AvatarSelection({...}))`.
class AvatarSelection extends Equatable {
  const AvatarSelection(this.optionByCategory);

  /// Mapa `categoryId -> optionId` con la opción elegida en cada categoría.
  /// Si una categoría no aparece como llave, se interpreta como "todavía sin
  /// selección explícita para esa categoría" (ver
  /// [AvatarCreatorController.selectedOptionFor], que resuelve ese caso
  /// devolviendo la primera opción de la categoría).
  final Map<String, String> optionByCategory;

  /// Devuelve el id de la opción elegida para [categoryId], o `null` si esa
  /// categoría todavía no tiene una selección registrada en este mapa.
  String? selectedOptionFor(String categoryId) => optionByCategory[categoryId];

  /// Devuelve una **nueva** [AvatarSelection] igual a esta, pero con
  /// [categoryId] apuntando ahora a [optionId]. No modifica la instancia
  /// actual (ver la explicación de inmutabilidad en el comentario de la
  /// clase).
  ///
  /// El operador `{...optionByCategory, categoryId: optionId}` es "spread"
  /// de colecciones en Dart: crea un mapa nuevo copiando todas las entradas
  /// de [optionByCategory] y luego sobreescribe (o agrega) la entrada
  /// `categoryId`. Como los mapas literales se procesan de izquierda a
  /// derecha, si `categoryId` ya existía en el mapa original, el valor
  /// nuevo (`optionId`) es el que queda.
  AvatarSelection withOption({required String categoryId, required String optionId}) {
    return AvatarSelection({...optionByCategory, categoryId: optionId});
  }

  @override
  List<Object?> get props => [optionByCategory];
}
