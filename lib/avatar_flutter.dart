/// Widget de creación y edición de avatar de Bancolombia.
///
/// Este archivo es el **"barrel export"** del paquete: la única puerta de
/// entrada pública desde fuera (`import 'package:avatar_flutter/avatar_flutter.dart';`).
/// Todo lo que un canal necesita usar se re-exporta desde aquí; el resto del
/// código, dentro de `lib/src/`, se considera **detalle de implementación**
/// interno del paquete y no debería importarse directamente desde fuera
/// (por convención de Dart, cualquier carpeta llamada `src/` dentro de
/// `lib/` se entiende como "privada del paquete", aunque el lenguaje no lo
/// fuerce técnicamente).
///
/// Para empezar, ver [AvatarCreatorScreen] (el punto de entrada visual) y
/// [AvatarCreatorConfig] (cómo personalizarlo desde el canal).
library;

export 'src/analytics/avatar_analytics_events.dart';
export 'src/avatar_creator_screen.dart';
export 'src/controllers/avatar_creator_controller.dart';
export 'src/data/avatar_catalog.dart';
export 'src/models/avatar_creator_config.dart';
export 'src/models/avatar_creator_result.dart';
export 'src/models/avatar_layer_category.dart';
export 'src/models/avatar_option.dart';
export 'src/models/avatar_selection.dart';
