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

## Uso básico

```dart
final resultado = await AvatarCreatorScreen.push(
  context,
  config: AvatarCreatorConfig(
    // initialSelection es un Future<Map<String, String>>? — pensado para
    // leer de SharedPreferences (que es async) sin bloquear la config.
    // Si se deja en null, es un avatar nuevo.
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

Puedes ver un ejemplo funcional completo en `example/lib/main.dart`: una
pantalla de perfil que ofrece "Cámara / Galería / Avatar / Cerrar" y, al
elegir "Avatar", abre `AvatarCreatorScreen` y usa el resultado para actualizar
el `CircleAvatar` de la pantalla.

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
| Diseño visual de header, preview, tabs, grid/row, footer | ✅ Fijado por la especificación de diseño | ❌ Solo puede cambiar los textos, vía `AvatarCreatorConfig` |
| Guardar la selección en memoria mientras el usuario navega entre tabs | ✅ `AvatarCreatorController` | — |
| Componer las capas seleccionadas en una imagen | ✅ `AvatarCreatorController.save()` (captura el `RepaintBoundary` del preview) | — |
| Persistir la imagen generada (subirla a un servidor, guardarla en disco/caché, asociarla al perfil del usuario) | ❌ La librería **nunca** hace esto | ✅ El canal, dentro de `onSaveSuccess` |
| Decidir qué pasa si falla el guardado (reintentar, mostrar un mensaje propio, loguear a un sistema de monitoreo) | ⚠️ La librería muestra un `SnackBar` genérico y expone el error | ✅ El canal, dentro de `onSaveError`, puede añadir su propio manejo |
| Analítica / tagueo (`avatar_creator_view`, `avatar_save`, ...) | ⚠️ Solo sugiere los nombres de evento (`AvatarAnalyticsEvents`) | ✅ El canal decide si los usa, con qué herramienta y cuándo — el widget nunca dispara analítica por sí mismo |
| Recuperar la última selección del usuario para reabrir el creador en modo "editar" | ❌ La librería no persiste nada entre sesiones | ✅ El canal guarda `resultado.selection` y la vuelve a pasar como `initialSelection` la próxima vez |
| Agregar nuevas variantes de arte (ej. un color o una forma más) | ✅ Es un cambio de datos en `avatar_catalog.dart`, sin tocar widgets | — |

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

### 2. Se crea el estado de la sesión de edición

En `initState()` de `_AvatarCreatorScreenState`, se crea un
`AvatarCreatorController` (`lib/src/controllers/avatar_creator_controller.dart`)
nuevo, pasándole:

* El catálogo de categorías: el que traiga `config.categories`, o si es
  `null`, `defaultAvatarCatalog()` (`lib/src/data/avatar_catalog.dart`) — el
  catálogo oficial de la librería.
* La selección inicial: la que traiga `config.initialSelection` (modo
  "editar"), o si es `null`, el controlador arma una selección "de fábrica"
  con la primera opción de cada categoría (modo "avatar nuevo").

Justo después de que la pantalla termina de pintar su primer frame, se llama
a `config.onView?.call()` — el primer punto donde el canal se entera de algo.

### 3. Se pinta la pantalla, conectada al controlador

`build()` envuelve todo con un `AvatarCreatorScope` (un `InheritedNotifier`
propio del paquete, sin depender de `provider` ni de ningún otro paquete de
gestión de estado externo) que expone el controlador a los widgets hijos. De
arriba a abajo, la pantalla arma:

1. **`AvatarPreview`** (`lib/src/widgets/avatar_preview.dart`): un rectángulo
   de alto fijo con el color de fondo elegido (`controller.backgroundColor`)
   y, encima, un `Stack` con las capas ilustradas seleccionadas
   (`controller.layerAssetPaths`), envuelto en un `RepaintBoundary` — esto
   último es clave para el paso de guardado (ver más abajo).
2. **`AvatarCategoryTabs`** (`lib/src/widgets/avatar_category_tabs.dart`): la
   fila de tabs, uno por categoría del catálogo, resaltando
   `controller.activeCategoryId`.
3. Según el `AvatarCategoryKind` de la categoría activa:
   * **`layer`** (Vestuario, Accesorios, Color de fondo): una sola sección,
     `AvatarSectionLabel` + **`AvatarOptionGrid`** (máx. 10 opciones).
   * **`layerWithColor`** (Cabello, Rostro): **dos** secciones seguidas — una
     fila de color (`AvatarOptionRow`, máx. 5) y debajo una cuadrícula de
     formas (`AvatarOptionGrid`, máx. 10). El color no se "aplica" en tiempo
     de ejecución: cada combinación de forma + color es un SVG real distinto
     (ver [assets reales](#assets-reales-el-color-viene-en-el-svg) más abajo).
     Cada opción, de cualquiera de las dos secciones, se dibuja con
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
  actualiza `controller.selection` (un `AvatarSelection` inmutable — cada
  cambio crea una instancia nueva en vez de mutar la anterior) y notifica —
  `AvatarPreview` se redibuja al instante con la nueva capa o el nuevo color
  de fondo.

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

Al tocar el botón de volver del header (`_handleCancel`; no hay botón
"Cancelar" en el footer): se llama a `config.onCancel?.call()` y la pantalla
simplemente se cierra sin devolver ningún resultado. Como el
`AvatarCreatorController` de esa sesión se destruye junto con la pantalla
(`dispose()`), cualquier selección hecha durante esa sesión se pierde — el
canal nunca llega a enterarse de una elección que el usuario no confirmó.

## Assets reales: el color viene en el SVG

Vestuario y Accesorios usan SVGs completos e independientes por opción (los
nombres de archivo son los que exportó Figma, por ejemplo
`Property 1=3.svg`, `Style=Style4.svg`); no tienen fila de color.

Cabello y Rostro sí la tienen, pero el color **no se aplica en tiempo de
ejecución** (no hay ningún `ColorFilter` ni tinte): diseño entregó un SVG ya
coloreado por cada combinación de forma y color (6 formas × 5 colores = 30
archivos por categoría, con nombres como `Color=3, Expression=5.svg`). Por
eso el `assetPath` de cada opción de forma en esas dos categorías es en
realidad una **plantilla** con el marcador `{color}` (por ejemplo,
`'assets/avatar/hair/Color={color}, Expression=1.svg'`), y
`AvatarLayerCategory.resolveAssetPath(formaElegida, colorElegido)` sustituye
ese marcador por el id del color para obtener la ruta real — tanto para la
capa del preview (`AvatarCreatorController.layerAssetPaths`) como para cada
miniatura de la cuadrícula (`AvatarOptionGrid.resolveAssetPath`), que por eso
recalculan su SVG cada vez que cambia el color elegido, no solo la miniatura
seleccionada.

Agregar una variante real más (una forma o un color adicional) es un cambio
de datos en `lib/src/data/avatar_catalog.dart` — no requiere tocar ningún
widget ni controlador.

## Desarrollo

```
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter run
```
