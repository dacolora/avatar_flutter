import 'package:flutter/material.dart';

/// Título de la sección de opciones (#6 "Label" de la especificación),
/// mostrado justo encima de la fila o cuadrícula de opciones de la
/// categoría activa (por ejemplo, "Cabello" o "Color de fondo").
///
/// Es intencionalmente el widget más simple de todo el paquete: solo recibe
/// un `String` y lo pinta con el estilo de texto correspondiente del tema
/// actual (`Theme.of(context).textTheme.titleSmall`), para que el texto se
/// vea consistente con el resto de la app anfitriona sin que este paquete
/// tenga que fijar una tipografía o tamaño de letra propios.
class AvatarSectionLabel extends StatelessWidget {
  const AvatarSectionLabel({required this.label, super.key});

  /// Texto a mostrar; normalmente [AvatarLayerCategory.label] de la
  /// categoría activa.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
