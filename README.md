# avatar_flutter

Widget de Flutter para crear y editar el avatar de un usuario, implementando
la especificación de diseño de Bancolombia **"WID - Avatar - APP"**: header +
preview en tiempo real + categorías de personalización (Rostro / Cabello /
Vestuario / Accesorios / Color de fondo) + guardado. Está pensado para
**embeberse** dentro de cualquier app ("canal") desde el punto donde ese
canal quiera ofrecer la edición de avatar (típicamente, un botón sobre la
foto de perfil).

Este documento tiene dos objetivos:

1. Explicar, paso a paso, cómo se construye la experiencia completa.
2. Dejar muy claro **qué es responsabilidad de esta librería** y **qué es
   responsabilidad del canal** que la consume — es la pregunta que más
   importa a la hora de integrar el widget, y la que genera más confusión si
   no se explicita.

Si eres nuevo en Flutter, esta guía asume que sabes lo básico (qué es un
`Widget`, qué es `build()`), pero explica con detalle los patrones más
específicos que usa este paquete. Cada clase, además, tiene su propio
comentario de documentación (`///`) en el código — este README da la vista
"de helicóptero", el código da el detalle de cada pieza.

## Instalación

```yaml
dependencies:
  avatar_flutter:
    git:
      url: https://github.com/dacolora/avatar_flutter.git
```

```dart
import 'package:avatar_flutter/avatar_flutter.dart';
```

Todo lo que necesitas se expone desde ese único import (ver
`lib/avatar_flutter.dart`, el "barrel export" del paquete). Todo lo que vive
dentro de `lib/src/` es detalle interno y no debería importarse directamente.

## Uso básico

`avatar_flutter` **no depende de `provider` ni de ningún otro paquete de
gestión de estado externo** — internamente usa únicamente `ChangeNotifier` e
`InheritedNotifier`, ambos parte del propio SDK de Flutter. Esto es
intencional: algunos canales no pueden asumir la dependencia de `provider`
(por conflicto de versiones, por arquitectura propia, etc.), así que el
paquete resuelve la compartición de estado sin necesitar nada externo. Ver la
sección de [arquitectura interna](#arquitectura-interna-sin-provider) más
abajo si te interesa el detalle.

```dart
final resultado = await AvatarCreatorScreen.push(
  context,
  config: AvatarCreatorConfig(
    // initialSelection es un Future<Map<String, String>>?, pensado para leer
    // de SharedPreferences (que es async) sin bloquear la construcción de
    // la config. Si se deja en null, es un avatar nuevo.
    initialSelection: leerSeleccionGuardada(),
    onSave: () => analytics.track(AvatarAnalyticsEvents.avatarSave),
    onSaveSuccess: (r) => analytics.track(AvatarAnalyticsEvents.avatarSaveSuccess),
    onSaveError: (e) => analytics.track(AvatarAnalyticsEvents.avatarSaveError),
  ),
);

if (resultado is AvatarCreatorResult) {
  // El widget solo generó la imagen (resultado.imageBytes) y la selección
  // (resultado.selection, un Map<String, String> plano). Subirla, guardarla
  // y asociarla al perfil es responsabilidad de ESTE código, del canal — ver
  // la sección siguiente.
  await miServicioDePerfil.actualizarAvatar(resultado.imageBytes);
  await guardarSeleccionEnSharedPreferences(resultado.selection);
}
```

Un patrón típico para `leerSeleccionGuardada()`/`guardarSeleccionEnSharedPreferences(...)`
usando `shared_preferences` (el mapa se codifica/decodifica con
`jsonEncode`/`jsonDecode` porque `SharedPreferences` solo guarda tipos
simples, no mapas):

```dart
Future<Map<String, String>> leerSeleccionGuardada() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('avatar_selection');
  if (json == null) return {};
  return Map<String, String>.from(jsonDecode(json) as Map);
}

Future<void> guardarSeleccionEnSharedPreferences(Map<String, String> selection) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('avatar_selection', jsonEncode(selection));
}
```

Puedes ver un ejemplo funcional completo (con esta misma integración de
`shared_preferences` ya cableada) en `example/lib/main.dart`: una pantalla de
perfil que ofrece "Cámara / Galería / Avatar / Cerrar" y, al elegir "Avatar",
abre `AvatarCreatorScreen` y usa el resultado para actualizar el
`CircleAvatar` de la pantalla y persistir la selección.

## ¿Qué es responsabilidad de la librería y qué es responsabilidad del canal?

Esta es la idea central del diseño de `avatar_flutter`: el widget se encarga
de **toda la experiencia visual de selección y composición del avatar**, pero
deliberadamente **no sabe nada** sobre cómo cada canal maneja persistencia,
red, o analítica. Esa frontera se materializa en el código de dos formas muy
concretas:

* [`AvatarCreatorConfig`] expone únicamente *callbacks* (`onView`, `onSave`,
  `onSaveSuccess`, `onSaveError`, `onCancel`). El widget los llama en el
  momento adecuado, pero nunca decide qué hacen — quien decide es quien los
  implementa, es decir, el canal.
* [`AvatarCreatorResult`] (lo que se recibe al guardar) solo trae los bytes de
  la imagen generada y la selección final. No hay ningún método
  `.guardar()` ni `.subirAServidor()` en esta clase — a propósito.

| Responsabilidad | Librería (`avatar_flutter`) | Canal (la app que la embebe) |
|---|---|---|
| Catálogo de categorías y su orden (Rostro, Cabello, Vestuario, Accesorios, Color de fondo) | ✅ Definido en `defaultAvatarCatalog()` | ❌ No se personaliza; viene de la especificación de diseño |
| Diseño visual de header, preview, tabs, grid/row, footer | ✅ Fijado por la especificación de diseño | ❌ Solo puede cambiar textos y habilitar/deshabilitar el botón secundario, vía `AvatarCreatorConfig` |
| Guardar la selección en memoria mientras el usuario navega entre tabs | ✅ `AvatarCreatorController` | — |
| Componer las capas seleccionadas en una imagen | ✅ `AvatarCreatorController.save()` (captura el `RepaintBoundary` del preview) | — |
| Persistir la imagen generada (subirla a un servidor, guardarla en disco/caché, asociarla al perfil del usuario) | ❌ La librería **nunca** hace esto | ✅ El canal, dentro de `onSaveSuccess` |
| Decidir qué pasa si falla el guardado (reintentar, mostrar un mensaje propio, loguear a un sistema de monitoreo) | ⚠️ La librería muestra un `SnackBar` genérico y expone el error | ✅ El canal, dentro de `onSaveError`, puede añadir su propio manejo |
| Analítica / tagueo (`avatar_creator_view`, `avatar_save`, ...) | ⚠️ Solo sugiere los nombres de evento (`AvatarAnalyticsEvents`) | ✅ El canal decide si los usa, con qué herramienta y cuándo — el widget nunca dispara analítica por sí mismo |
| Recuperar la última selección del usuario para reabrir el creador en modo "editar" | ❌ La librería no persiste nada entre sesiones | ✅ El canal guarda `resultado.selection` y la vuelve a pasar como `initialSelection` la próxima vez |
| Agregar nuevas variantes de arte (ej. `hair_2.svg`) | ✅ Es un cambio de datos en `avatar_catalog.dart`, sin tocar widgets | — |

La regla general para recordar: **la librería termina su trabajo en el
momento en que te entrega un `AvatarCreatorResult`**. Todo lo que pasa antes
de ese momento (mostrar las opciones, seleccionar, ver el preview en vivo,
generar la imagen) es la librería; todo lo que pasa después (qué haces con esa
imagen y esa selección) es el canal.

## Paso a paso: cómo se construye la experiencia

Esta sección recorre, en orden de ejecución real, todo lo que pasa desde que
el canal abre el widget hasta que lo cierra guardando o cancelando. Los
nombres entre paréntesis son las clases involucradas — puedes seguir la
lectura abriendo esos archivos en paralelo.

### 1. El canal abre la pantalla

El canal llama a `AvatarCreatorScreen.push(context, config: ...)`
(`lib/src/avatar_creator_screen.dart`). Esto empuja una ruta nueva de
Flutter (`Navigator.push`) con `AvatarCreatorScreen` dentro, pasándole la
`AvatarCreatorConfig` que el canal haya armado (o ninguna, si le sirven todos
los valores por defecto).

### 2. Se espera la selección inicial (si viene de un `Future`) y se crea el controlador

Si `config.initialSelection` es `null` (avatar nuevo), `initState()` crea el
`AvatarCreatorController` (`lib/src/controllers/avatar_creator_controller.dart`)
de inmediato, sin ningún estado de carga. Si en cambio trae un
`Future<Map<String, String>>` (por ejemplo, la lectura de `SharedPreferences`
del canal), la pantalla lo espera primero — mostrando un
`CircularProgressIndicator` mientras tanto — y solo entonces crea el
controlador, pasándole:

* El catálogo de categorías: el que traiga `config.categories`, o si es
  `null`, `defaultAvatarCatalog()` (`lib/src/data/avatar_catalog.dart`) — el
  catálogo oficial de la librería.
* La selección inicial: el mapa resuelto por el `Future` (modo "editar"), o
  si no había `Future`, el controlador arma una selección "de fábrica" con la
  primera opción de cada categoría (modo "avatar nuevo").

Justo después de que la pantalla termina de pintar el primer frame con el
controlador ya listo, se llama a `config.onView?.call()` — el primer punto
donde el canal se entera de algo.

### 3. Se pinta la pantalla, conectada al controlador

`build()` envuelve todo con un `AvatarCreatorScope` (un `InheritedNotifier`
propio del paquete — ver la sección de [arquitectura interna](#arquitectura-interna-sin-provider))
que expone el controlador a los widgets hijos, sin depender de `provider`. De
arriba a abajo, la pantalla arma:

1. **`AvatarPreview`** (`lib/src/widgets/avatar_preview.dart`): un cuadrado
   con el color de fondo elegido (`controller.backgroundColor`) y, encima,
   un `Stack` con las capas ilustradas seleccionadas
   (`controller.previewLayers`), envuelto en un `RepaintBoundary` — esto
   último es clave para el paso de guardado (ver más abajo).
2. **`AvatarCategoryTabs`** (`lib/src/widgets/avatar_category_tabs.dart`): la
   fila de tabs, uno por categoría del catálogo, resaltando
   `controller.activeCategoryId`.
3. Según el `AvatarCategoryKind` de la categoría activa:
   * **`layer`** (Vestuario, Accesorios, Color de fondo): una sola sección,
     `AvatarSectionLabel` + **`AvatarOptionGrid`** (máx. 10 opciones).
   * **`layerWithColor`** (Cabello, Rostro): **dos** secciones seguidas —
     `AvatarSectionLabel` + **`AvatarOptionRow`** con la fila de color (máx.
     5), y debajo otro `AvatarSectionLabel` + **`AvatarOptionGrid`** con la
     fila de formas (máx. 10), donde el color elegido tiñe todas las formas
     (ver la sección de [tinte de color](#tinte-de-color-sin-svgs-nuevos) más
     abajo). Cada opción, de cualquiera de las dos secciones, se dibuja con
     **`AvatarSelectableThumbnail`**, la miniatura cuadrada compartida por
     ambos widgets.
4. En `bottomNavigationBar` (fijo, fuera del área con scroll): el botón
   "Guardar". No hay un botón "Cancelar" en el footer — cancelar se hace
   desde el botón de volver del header.

Todo el contenido de arriba (1 a 3) vive dentro de un único
`SingleChildScrollView`, sin ningún `Expanded` — una decisión deliberada para
evitar un bug real observado en Safari/iOS donde un `Expanded` puede colapsar
a 0px cuando la barra de direcciones del navegador cambia de tamaño.

### 4. El usuario interactúa

* **Tocar un tab** llama a `controller.selectCategory(id)`: cambia
  `activeCategoryId` y notifica — la pantalla se redibuja mostrando las
  opciones de la nueva categoría, pero la selección de las demás categorías
  no se pierde (queda guardada en `controller.selection`).
* **Tocar una opción** llama a `controller.selectOption(categoryId, optionId)`:
  actualiza la selección interna del controlador (representada como un mapa
  inmutable — cada cambio crea una copia nueva en vez de mutar la anterior) y
  notifica — `AvatarPreview` se redibuja al instante con la nueva capa o el
  nuevo color de fondo.

Ningún cambio se persiste ni se envía a ningún lado en este punto: todo vive
en memoria, dentro del `AvatarCreatorController` de esa sesión de edición.

### 5. Guardar

Al tocar "Guardar" (`_handleSave` en `avatar_creator_screen.dart`):

1. Se llama a `config.onSave?.call()`.
2. Se llama a `controller.save()`, que:
   * Ubica el `RepaintBoundary` del preview a través de la `GlobalKey`
     compartida (`previewBoundaryKey`).
   * Le pide que renderice su contenido actual como una imagen
     (`RenderRepaintBoundary.toImage()`) y la codifica como PNG.
   * Empaqueta la selección final + los bytes del PNG en un
     `AvatarCreatorResult`.
3. Si todo salió bien: se llama a `config.onSaveSuccess?.call(resultado)` y
   la pantalla se cierra devolviendo ese `resultado` a quien llamó a
   `AvatarCreatorScreen.push(...)`.
4. Si algo falla (por ejemplo, el preview no llegó a montarse): se llama a
   `config.onSaveError?.call(error)` y se muestra un `SnackBar` genérico,
   **sin cerrar la pantalla** — el usuario puede intentar de nuevo.

Aquí termina el trabajo de la librería. **A partir de este punto, es 100%
responsabilidad del canal** decidir qué hacer con `resultado.imageBytes` y
`resultado.selection` (ver la tabla de responsabilidades más arriba).

### 6. Cancelar

Al tocar el botón de volver del header (`_handleCancel`; no hay un botón
"Cancelar" en el footer): se llama a `config.onCancel?.call()` y la pantalla
simplemente se cierra sin devolver ningún resultado. Como el
`AvatarCreatorController` de esa sesión se
destruye junto con la pantalla (`dispose()`), cualquier selección hecha
durante esa sesión se pierde — el canal nunca llega a enterarse de una
elección que el usuario no confirmó.

## Arquitectura interna: sin `provider`

Antes de compartirlo, el estado del creador de avatar (categoría activa,
selección, si está guardando, errores) se manejaba con
`ChangeNotifierProvider` + `Consumer`/`context.watch` del paquete `provider`.
Como algunos canales no pueden depender de `provider`, se reemplazó por dos
piezas que **ya vienen incluidas en el SDK de Flutter**, sin ninguna
dependencia nueva:

* **`AvatarCreatorController`** sigue siendo un `ChangeNotifier` normal
  (`package:flutter/foundation.dart`) — eso no cambió, `ChangeNotifier` nunca
  fue parte de `provider`, es del propio Flutter.
* **`AvatarCreatorScope`** (`lib/src/controllers/avatar_creator_scope.dart`)
  es un `InheritedNotifier<AvatarCreatorController>` — también parte del SDK
  de Flutter (`package:flutter/widgets.dart`) — que cumple exactamente el
  mismo rol que `ChangeNotifierProvider`: expone el controlador a los
  widgets descendientes y los reconstruye automáticamente cada vez que el
  controlador llama a `notifyListeners()`.

Un widget interno accede al controlador con `AvatarCreatorScope.of(context)`
en vez de `context.watch<AvatarCreatorController>()`. Fuera de ese cambio de
sintaxis, el comportamiento es idéntico: es un reemplazo interno, transparente
para el canal — `AvatarCreatorScope` ni siquiera se exporta desde
`avatar_flutter.dart`, porque el canal nunca necesita tocarlo directamente.

## Tinte de color sin SVGs nuevos

Cabello y Rostro no solo eligen una forma (corte de pelo / expresión):
también eligen un color (color de pelo / tono de piel) en una fila aparte
(ver [`AvatarCategoryKind.layerWithColor`](lib/src/models/avatar_layer_category.dart)).
Ese color **no** se resuelve con más SVGs — se aplica en tiempo real con un
[`ColorFilter.mode(color, BlendMode.srcIn)`](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
sobre el SVG existente, que repinta cada píxel opaco del dibujo con el color
elegido, conservando su forma intacta. Por eso, si el usuario elige "morado"
en "Color del pelo":

* La capa de pelo del preview (`AvatarPreview`) se pinta morada al instante.
* **Las 10 miniaturas** de la cuadrícula "Forma del pelo" (`AvatarOptionGrid`)
  también se pintan moradas — no solo la que esté seleccionada — porque
  `AvatarOptionGrid` recibe ese mismo color como `tint` y lo aplica a todas
  sus miniaturas por igual (`AvatarSelectableThumbnail.tint`).

Esta técnica funciona perfecto para ilustraciones de un solo tono (como las
formas de pelo). Si en el futuro un SVG necesita un detalle en un segundo
tono que **no** deba teñirse (por ejemplo, un ojo o una boca en la expresión
del rostro, en contraste con el tono de piel), un `ColorFilter` sobre todo el
SVG no alcanza — haría falta separar ese detalle en un asset propio (o
reestructurar el SVG) para poder teñir solo la parte de "piel" y dejar el
detalle intacto.

## Estado de los assets

Las categorías de capa (Rostro, Cabello, Vestuario, Accesorios) están
cableadas hoy al primer asset de muestra entregado por diseño
(`{categoria}_1.svg`), repetido en varios slots seleccionables como
placeholder, para que todo el flujo (selección → preview en tiempo real →
guardado) ya funcione de punta a punta con datos reales. Agregar una
variante real (por ejemplo `face_2.svg`) es un cambio de datos en
`lib/src/data/avatar_catalog.dart` — se agrega un `AvatarOption.layer(...)`
apuntando al nuevo SVG — y no requiere tocar ningún widget ni controlador.

## Desarrollo

```
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter run
```
