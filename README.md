# avatar_flutter

Widget de creación y edición de avatar del SDB (Bancolombia), listo para
embeberse en cualquier canal desde el botón de edición de avatar del perfil.
Implementa la especificación "WID - Avatar - APP": header + preview en tiempo
real + categorías de personalización (Rostro / Cabello / Vestuario /
Accesorios / Color de fondo) + guardado, reutilizando `BcHeader`,
`BcIconButton`, `BcCardContainer` y `BcButtonsFooter` de `bds_mobile`.

## Estado de los assets

Las categorías de capa (Rostro, Cabello, Vestuario, Accesorios) están cableadas
al primer asset de muestra entregado por diseño (`{categoria}_1.svg`), repetido
en varios slots seleccionables como placeholder. Agregar una variante real
(`face_2.svg`, `hair_3.svg`, …) es un cambio de datos en
`lib/src/data/avatar_catalog.dart`, no de código.

## Uso básico

```dart
import 'package:avatar_flutter/avatar_flutter.dart';

final result = await AvatarCreatorScreen.push(
  context,
  config: AvatarCreatorConfig(
    initialSelection: currentAvatarSelection, // null = avatar nuevo
    onSave: () => analytics.track(AvatarAnalyticsEvents.avatarSave),
    onSaveSuccess: (result) => analytics.track(AvatarAnalyticsEvents.avatarSaveSuccess),
    onSaveError: (error) => analytics.track(AvatarAnalyticsEvents.avatarSaveError),
  ),
);

if (result is AvatarCreatorResult) {
  // El widget solo genera la imagen (result.imageBytes); sincronizarla con
  // el perfil es responsabilidad del canal.
}
```

`bds_mobile` espera que la app anfitriona provea sus foundations
(`BcThemeNotifier`, `BcBrandNotifier`, `CoreFoundations.themeProvider`) en la
raíz del árbol de widgets — ver `example/lib/main.dart` para el setup mínimo.

## Desarrollo

```
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter run
```
