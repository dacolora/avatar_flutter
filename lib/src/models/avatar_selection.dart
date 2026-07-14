import 'package:equatable/equatable.dart';

/// Snapshot inmutable de la selección actual del usuario: una opción
/// seleccionada por categoría (`categoryId -> optionId`), incluyendo la
/// categoría de color de fondo (tratada como una categoría más).
class AvatarSelection extends Equatable {
  const AvatarSelection(this.optionByCategory);

  final Map<String, String> optionByCategory;

  String? selectedOptionFor(String categoryId) => optionByCategory[categoryId];

  AvatarSelection withOption({required String categoryId, required String optionId}) {
    return AvatarSelection({...optionByCategory, categoryId: optionId});
  }

  @override
  List<Object?> get props => [optionByCategory];
}
