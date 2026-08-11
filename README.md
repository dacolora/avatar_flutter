# avatar_flutter

Widget de Flutter para crear y editar el avatar de un usuario, implementando
la especificación de diseño de Bancolombia **"WID - Avatar - APP"**: header +
preview en tiempo real + categorías de personalización (Vestuario / Cabello /
Rostro / Color de fondo) + guardado. Está pensado para
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
    onSave: () => analytics.track('avatar_save'),
    onSaveSuccess: (r) => analytics.track('avatar_save_success'),
    onSaveError: (e) => analytics.track('avatar_save_error'),
  ),
);

if (resultado is AvatarCreatorResult) {
  // El widget solo generó la imagen (resultado.imageBytes) y la selección
  // (resultado.selection, un Map<String, String> plano). Subirla, guardarla
  // y asociarla al perfil es responsabilidad de ESTE código, del canal — ver
  // la sección siguiente.
  await miServicioDePerfil.actualizarAvatar(resultado.imageBytes);
  await guardarSeleccionEnSharedPreferences(resultado.selection);

  // resultado.imageProvider entrega esos mismos bytes ya envueltos en un
  // ImageProvider (MemoryImage), listo para mostrarse sin construirlo a
  // mano — útil cuando lo que necesitas es pintar la imagen, no subirla.
  setState(() => _avatarImageProvider = resultado.imageProvider);
}
```

Puedes ver un ejemplo funcional completo en `example/lib/main.dart`: una
pantalla de perfil con dos tarjetas, cada una abriendo `AvatarCreatorScreen`
y orquestando el resultado de una forma distinta — ver "Dos formas de
orquestar la imagen del avatar" más abajo.

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
  la imagen generada (`imageBytes`, más `imageProvider` como conveniencia —
  el mismo `Uint8List` ya envuelto en un `MemoryImage`, listo para pintarse)
  y la selección final. No hay ningún método `.guardar()` ni
  `.subirAServidor()` en esta clase — a propósito.

| Responsabilidad | Librería (`avatar_flutter`) | Canal (la app que la embebe) |
|---|---|---|
| Catálogo oficial y su orden (Rostro, Cabello, Vestuario, Accesorios, Color de fondo) | ✅ Definido en `defaultAvatarCatalog()`, es lo que se usa si el canal no pasa `categories` | ⚠️ Puede reemplazarlo por completo — con menos categorías, con más, o agregando una propia (ver [Personalización](#personalización-qué-puede-parametrizar-el-canal)) |
| Diseño visual de header, preview, tabs, grid/row, footer | ✅ Fijado por la especificación de diseño | ⚠️ Puede cambiar textos, alturas del preview, columnas del grid y máximos por categoría — ver `AvatarCreatorConfig` |
| Guardar la selección en memoria mientras el usuario navega entre tabs | ✅ `AvatarCreatorController` | — |
| Componer las capas seleccionadas en una imagen | ✅ `AvatarCreatorController.save()` (captura el `RepaintBoundary` del preview) | — |
| Persistir la imagen generada (subirla a un servidor, guardarla en disco/caché, asociarla al perfil del usuario) | ❌ La librería **nunca** hace esto | ✅ El canal, dentro de `onSaveSuccess` |
| Decidir qué pasa si falla el guardado (reintentar, mostrar un mensaje propio, loguear a un sistema de monitoreo) | ⚠️ La librería muestra un `SnackBar` genérico y expone el error | ✅ El canal, dentro de `onSaveError`, puede añadir su propio manejo |
| Analítica / tagueo | ❌ La librería nunca dispara ningún evento de analítica por sí misma | ✅ El canal decide si, cuándo, con qué nombre y con qué herramienta registrar eventos dentro de sus propios callbacks (`onView`, `onSave`, ...) |
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
   con un lavado **pálido y opaco** (una mezcla de 25% con blanco, no
   opacidad real — ver por qué en la sección de [scroll](#scroll-preview-que-se-encoge-tabs-fijos-body-que-se-desplaza)) del
   color de fondo elegido, y centrado dentro, un **círculo** con ese mismo
   color pero sólido — como un `CircleAvatar` — con un `Stack` de las capas
   ilustradas seleccionadas encima (`controller.layerAssetPaths`). Solo el
   círculo (no el rectángulo completo) está envuelto en un
   `RepaintBoundary`, clave para el paso de guardado (ver más abajo): lo
   que se guarda es el círculo con el avatar, no el fondo decorativo de la
   pantalla. Este rectángulo **se encoge** al hacer scroll, entre los altos
   que indique `AvatarCreatorConfig.previewExpandedHeight`/
   `previewCollapsedHeight` (249/160 por defecto, personalizables por el
   canal).
2. **`AvatarCategoryTabs`** (`lib/src/widgets/avatar_category_tabs.dart`): la
   fila de tabs, uno por categoría del catálogo, resaltando
   `controller.activeCategoryId`. A diferencia del preview, esta fila
   **no** se encoge: mantiene siempre el mismo alto fijo
   (`AvatarCategoryTabs.height`), y tiene fondo blanco **opaco** por el
   mismo motivo que el lavado pálido del preview.
3. Según el `AvatarCategoryKind` de la categoría activa:
   * **`layer`** (hoy, solo "Color de fondo"): una sola sección,
     `AvatarSectionLabel` + **`AvatarOptionGrid`** (máx. 10 opciones, 2
     columnas por defecto — ambos configurables, ver
     [Personalización](#personalización-qué-puede-parametrizar-el-canal)).
   * **`layerWithColor`** (Vestuario, Cabello, Rostro): **dos** secciones
     seguidas — una fila de color (`AvatarOptionRow`, máx. 5 por defecto) y
     debajo una cuadrícula de formas (`AvatarOptionGrid`, máx. 10 por
     defecto). El color no se "aplica" en tiempo de ejecución: cada
     combinación de forma + color es un SVG real distinto (ver
     [assets reales](#assets-reales-el-color-viene-en-el-svg) más abajo).
     Cada opción, de cualquiera de las dos secciones, se dibuja con
     **`AvatarSelectableThumbnail`**, la miniatura cuadrada compartida por
     ambos widgets — usando, si existe, la versión de la ilustración pensada
     para verse bien de chica (ver
     [assets reales](#assets-reales-el-color-viene-en-el-svg)).
4. En `bottomNavigationBar` (fijo, fuera del área con scroll): el botón
   "Guardar". No hay un botón "Cancelar" en el footer — cancelar se hace
   desde el botón de volver del header.

## Scroll: preview que se encoge, tabs fijos, body que se desplaza

El `body` de la pantalla es un `CustomScrollView` con tres slivers, para
lograr un comportamiento de scroll específico:

1. **El preview se encoge, pero nunca desaparece.** Es un
   `SliverPersistentHeader` con `pinned: true` cuyo alto va de
   `AvatarCreatorConfig.previewExpandedHeight` (249 por defecto, arriba del
   todo) a `previewCollapsedHeight` (160 por defecto, el mínimo) a medida
   que el usuario hace scroll hacia abajo, y vuelve a expandirse al subir —
   nunca llega a ocultarse del todo. Ambos altos son configurables por el
   canal (ver `example/lib/main.dart`); `AvatarPreview` no tiene una
   opinión propia sobre cuáles deberían ser, solo sabe interpolar entre los
   que le pasen. Recibe el progreso del encogimiento como un valor
   `expansion` entre `0` (encogido) y `1` (expandido) y lo usa para
   interpolar tanto su alto como el diámetro del círculo (siempre el 80%
   del alto), sin animación: como `expansion` cambia en cada frame de
   scroll, animarlo produciría un desfase entre el dedo y el preview.
2. **Los tabs de categoría quedan siempre fijos, justo debajo del preview.**
   Es otro `SliverPersistentHeader` con `pinned: true`, pero con
   `minExtent == maxExtent` (`AvatarCategoryTabs.height`): no se encoge, y
   como está `pinned`, tampoco se desplaza fuera de la pantalla — sea cual
   sea la posición del scroll, los tabs siempre están a la vista y son
   tocables.
3. **El resto del contenido** (etiqueta de sección + fila de color/cuadrícula
   de formas) va en un `SliverToBoxAdapter` normal: es la única parte que
   en verdad se desplaza fuera de la pantalla al hacer scroll — de ahí el
   nombre de esta sección: "el scroll es del body de cada categoría", no de
   toda la pantalla.

Ambos headers usan el mismo delegate reutilizable
(`_SliverHeaderDelegate`, privado de `avatar_creator_screen.dart`), que
adapta cualquier widget a la interfaz que pide `SliverPersistentHeader`
sin tener que escribir una subclase por header.

### Por qué el preview y los tabs necesitan fondo opaco (no transparente)

`SliverPersistentHeader(pinned: true)` pinta su contenido por encima de lo
que scrollea debajo — así funciona cualquier header fijo de Flutter (por
ejemplo, un `SliverAppBar` pinned). Pero "pintarse encima" en el orden de
capas no sirve de nada si el fondo del header es transparente: el contenido
scrolleado seguiría siendo visible **a través** de él. `AvatarCategoryTabs`
tenía justo ese bug (su `Container` solo definía un borde, sin `color`) y
`AvatarPreview` usaba opacidad real (`color.withOpacity(0.25)`) en vez de un
color pálido sólido — en ambos casos, el body scrolleado terminaba
"asomándose" detrás del preview/los tabs en vez de quedar tapado por
completo. La corrección en los dos widgets fue la misma: usar un color
**opaco** (mezclado con blanco para lograr el tono pálido, no
`withOpacity`) tanto en el preview como en el fondo blanco de los tabs.

Igual que con el `SingleChildScrollView` que se usaba antes de este
rediseño, esto sigue evitando cualquier `Expanded`: un `CustomScrollView`
como `body` de un `Scaffold` simplemente ocupa la altura que le den (aunque
esa altura fluctúe momentáneamente, como pasa en Safari/iOS cuando la barra
de direcciones aparece o desaparece), sin que ninguno de sus slivers deba
repartirse una porción fija de esa altura y arriesgarse a colapsar a 0px —
el contenido siempre sigue siendo alcanzable con scroll, sin importar la
altura real disponible en cada momento.

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

## Personalización: qué puede parametrizar el canal

Como cada canal embebe esta experiencia con necesidades distintas, la regla
de diseño de `avatar_flutter` es: **todo lo que se pueda parametrizar sin
romper la especificación oficial, se expone en `AvatarCreatorConfig`, con un
valor por defecto igual al de la especificación**. Un canal que no toca nada
obtiene exactamente la experiencia oficial de Bancolombia; un canal que
necesita algo distinto tiene el control real, no solo la ilusión de tenerlo.

| Parámetro | Valor por defecto | Qué controla |
|---|---|---|
| `categories` | `defaultAvatarCatalog()` | El catálogo completo — ver más abajo |
| `initialSelection` | `null` (avatar nuevo) | Reabrir un avatar ya guardado |
| `title` / `backButtonLabel` / `saveButtonText` | textos oficiales en español | Los textos visibles del header/footer |
| `previewExpandedHeight` / `previewCollapsedHeight` | `249` / `160` | Los altos del preview al abrir y tras hacer scroll del todo |
| `gridCrossAxisCount` | `2` | Columnas de la cuadrícula de opciones ilustradas |
| `maxGridOptions` | `12` | Máximo de opciones en una cuadrícula |
| `maxRowOptions` | `6` | Máximo de opciones en una fila de color |
| `onView` / `onSave` / `onSaveSuccess` / `onSaveError` / `onCancel` | sin efecto | Los puntos de extensión para analítica/persistencia (ver tabla de responsabilidades) |

`example/lib/customization_gallery.dart` es una galería ejecutable con siete
demos, alcanzable desde el ícono de ajustes (⚙️) de la barra superior de
`example/lib/main.dart`: la experiencia por defecto, un formulario
interactivo para tocar cada parámetro en vivo, un catálogo de solo 2
categorías, uno de 6, uno con una categoría que la librería no contempla,
reabrir un avatar existente, y los callbacks conectados a `SnackBar`s
visibles.

### El catálogo es del canal, no solo de la librería

`AvatarCreatorConfig.categories` no es una puerta trasera para tests: es el
punto de extensión pensado para que un canal arme su propia experiencia —
reduciendo el catálogo oficial, extendiéndolo, o agregando una categoría que
esta librería nunca contempló. El controlador no le da ningún trato especial
al catálogo oficial: `AvatarCreatorController.layerAssetPaths` simplemente
recorre `categories` en el orden en que vengan, sea cual sea su origen.

```dart
// El canal solo necesita dos categorías.
AvatarCreatorConfig(
  categories: [
    defaultAvatarCatalog().firstWhere((c) => c.id == 'body'),
    defaultAvatarCatalog().firstWhere((c) => c.id == 'background'),
  ],
)

// El canal agrega una categoría propia, con su propio SVG.
AvatarLayerCategory(
  id: 'badge',
  label: 'Insignia',
  icon: Icons.military_tech_outlined,
  kind: AvatarCategoryKind.layer,
  options: const [
    AvatarOption.layer(id: '1', assetPath: 'assets/badge/insignia_1.svg'),
  ],
)
```

Para que ese último ejemplo funcione de verdad hay un detalle importante:
**`AvatarOption.assetPackage`**. `AvatarPreview` y `AvatarSelectableThumbnail`
dibujan cada SVG con `SvgPicture.asset(path, package: ...)`, y ese parámetro
`package` de Flutter le dice al framework en qué paquete buscar el asset — no
es cosmético. Las opciones del catálogo oficial fijan
`assetPackage: 'avatar_flutter'` porque sus SVGs viven empaquetados dentro de
este paquete; una categoría propia del canal debe **dejar `assetPackage` en
`null`** (su valor por defecto), para que el asset se busque en el bundle de
la propia app del canal — donde lo haya declarado bajo `flutter: assets:` en
su propio `pubspec.yaml`.

## Assets reales: el color viene en el SVG, y el preview no es la miniatura

Vestuario, Cabello y Rostro son las tres categorías `layerWithColor` del
catálogo oficial. El color **no se aplica en tiempo de ejecución** (no hay
ningún `ColorFilter` ni tinte): diseño entrega un SVG ya coloreado por cada
combinación de forma y color —por ejemplo, Vestuario tiene 6 colores × 8
estilos = 48 archivos—. Por eso el `assetPath` de cada opción de forma en
estas categorías es en realidad una **plantilla** con el marcador `{color}`
(por ejemplo, `'assets/avatar/hair/hair_{color}_3.svg'`), y
`AvatarLayerCategory.resolveAssetPath(formaElegida, colorElegido)` sustituye
ese marcador por el id del color para obtener la ruta real.

Accesorios y Color de fondo son las categorías `layer` del catálogo oficial
(una sola cuadrícula, sin fila de color). Color de fondo son colores sólidos
([`AvatarOption.color`]), sin ningún SVG detrás; Accesorios sí tiene SVGs,
pero solo uno por opción (no una combinación de forma + color como
Vestuario/Cabello/Rostro), y además incluye "Sin accesorios"
([`AvatarOption.none`]) preseleccionada por defecto, porque un accesorio es
opcional por naturaleza.

### Dos archivos por combinación: preview y miniatura

Cada combinación de forma + color en Vestuario/Cabello/Rostro tiene, en
realidad, **dos** SVGs — no uno:

* `assets/avatar/$id/${id}_{color}_{forma}.svg` — pensado para apilarse con
  las demás capas dentro del círculo del preview.
* `assets/avatar/ct_$id/ct_${id}_{color}_{forma}.svg` — pensado para verse
  bien solo, dentro del cuadro chico de la cuadrícula de selección.

Son necesarios los dos porque un mismo SVG, dimensionado y posicionado para
calzar con las demás capas del preview, no se ve bien recortado dentro de una
miniatura pequeña (y viceversa). [`AvatarOption`] modela esto con dos campos:
`assetPath` (el del preview) y `thumbnailAssetPath` (el de la miniatura, o
`null` si la ilustración se ve igual de bien en los dos tamaños — el caso
normal para una categoría propia del canal). `AvatarLayerCategory` tiene un
método de resolución para cada uno:

* `resolveAssetPath(forma, color)` — la ruta para el preview
  (`AvatarCreatorController.layerAssetPaths` la usa).
* `resolveThumbnailAssetPath(forma, color)` — la ruta para la miniatura
  (`AvatarOptionGrid.resolveThumbnailAssetPath` la usa); cae de vuelta a
  `resolveAssetPath` si la opción no tiene `thumbnailAssetPath` propio.

Ambos recalculan la ruta cada vez que cambia el color elegido — de ahí que
**todas** las miniaturas de la cuadrícula, no solo la seleccionada, se
actualicen cuando el usuario elige un color distinto en la fila de arriba.

Agregar una variante real más (una forma o un color adicional) es un cambio
de datos en `lib/src/data/avatar_catalog.dart` — no requiere tocar ningún
widget ni controlador.

## Mostrar un avatar sin abrir el creador: `AvatarStaticPreview`

`AvatarCreatorScreen` es la experiencia completa de *edición*. Pero mostrar
un avatar ya elegido —en una lista de usuarios, un encabezado de perfil, una
tarjeta— no debería requerir navegar a esa pantalla completa solo para ver
cómo se superponen los SVGs de una selección que el canal ya tiene guardada.
Para eso existe `AvatarStaticPreview`: un widget liviano que arma la misma
composición (color de fondo + capas apiladas) directamente a partir de un
`Map<String, String>`, sin `Navigator`, sin `AvatarCreatorScope` y sin
`RepaintBoundary` (no es para guardarse, solo para mostrarse).

```dart
AvatarStaticPreview(
  selection: seleccionGuardada, // el mismo Map<String, String> de siempre
  size: 40, // diámetro del círculo, en píxeles lógicos
)
```

Si el canal usó un catálogo propio (`AvatarCreatorConfig.categories`) para
generar esa selección, hay que pasarle el mismo catálogo con `categories:`;
si se omite, usa `defaultAvatarCatalog()`. Una selección con ids
desconocidos o incompletos no lanza ninguna excepción: se resuelve con el
mismo respaldo que usa `AvatarCreatorController` (primera opción de la
categoría, o transparente si no hay categoría de fondo) — por dentro,
`AvatarStaticPreview` arma un `AvatarCreatorController` desechable
únicamente para reutilizar esa lógica de resolución, sin insertarlo en el
árbol de widgets ni escucharlo.

## Dos formas de orquestar la imagen del avatar

`AvatarCreatorResult` le da al canal dos cosas — `selection` (texto, unas
decenas de bytes) e `imageBytes` (el PNG ya renderizado) — y **cuáles de
las dos persiste, y cómo**, es una decisión del canal, con tradeoffs
distintos. Para que esa decisión sea visible en vez de quedar escondida
dentro de un solo flujo, `ProfileScreen` (`example/lib/main.dart`) muestra
**dos tarjetas independientes**, cada una orquestando la imagen a su
manera, sin compartir estado ni almacenamiento entre sí:

| | Opción A — `MapOnlyAvatarCard` | Opción B — `CachedImageAvatarCard` |
| --- | --- | --- |
| Qué persiste | Solo `result.selection` (`SharedPreferences`) | Solo el PNG de `result.imageBytes` (`AvatarImageCache`) |
| Cómo se muestra | Se recompone en vivo con `AvatarStaticPreview` cada vez | Se relee el archivo ya renderizado con `CachedAvatarImage` |
| Costo de guardar | Mínimo (texto) | Mayor (el PNG completo) |
| Costo de mostrar | Recompone las capas SVG cada vez | Ninguno: ya está renderizado |
| Reabrir el editor | Arranca con la última selección (`initialSelection`) | Arranca en blanco — no hay mapa guardado con qué prellenarlo |
| Además dispara | Nada más | Sincroniza el widget nativo de pantalla de inicio y descarga el JPG |

Ninguna de las dos es "la correcta": un canal que solo necesita mostrar el
avatar en un lugar barato de recomponer (poco tráfico, tamaño chico) puede
preferir la Opción A; uno que lo muestra en muchos lugares o lo necesita
también para el widget nativo / la descarga en JPG sale ganando con la
Opción B. Nada impide combinar ambas (como hacía este ejemplo antes de
separarlas en dos tarjetas) — separarlas acá es a propósito, para que el
tradeoff quede notorio.

### Opción B, en detalle: `AvatarImageCache`

`AvatarImageCache` (`example/lib/avatar_image_cache.dart`) guarda el PNG en
el **directorio de caché de la app**, en el celular de quien la está
usando —no en memoria, no en esta computadora, no en ningún servidor—, con
[`path_provider`](https://pub.dev/packages/path_provider):

```dart
final directory = await getApplicationCacheDirectory();
final file = File('${directory.path}/avatar_cache.png');
await file.writeAsBytes(imageBytes, flush: true);
```

Es justamente lo que en Android es `context.cacheDir` y en iOS
`Library/Caches`: persiste entre sesiones (a diferencia de un campo en
memoria), pero el sistema operativo lo puede liberar si el dispositivo
necesita espacio — por eso `AvatarImageCache.read()` puede devolver `null`.

Ese archivo se lee a través de un widget reutilizable,
`CachedAvatarImage` (`example/lib/cached_avatar_image.dart`), que no
depende de ningún estado en memoria: cada instancia relee el mismo archivo
por su cuenta, así que se puede usar en **cualquier pantalla**, no solo en
la que guardó la imagen. `CustomizationGalleryScreen` lo demuestra
mostrando la misma imagen cacheada por `CachedImageAvatarCard` en su propio
`AppBar`, sin que nadie le pase el estado a mano:

```dart
CachedAvatarImage(radius: 56, selectionFallback: seleccionSiLaHay)
```

`selectionFallback` es opcional: si se le pasa una selección persistida
(como hace la Opción A) y todavía no hay nada cacheado —primer uso, o el
sistema operativo liberó el caché—, cae de vuelta a `AvatarStaticPreview`
en vez de mostrar un placeholder vacío. `CachedImageAvatarCard` no le pasa
ninguna, a propósito, para que quede claro que esta tarjeta no tiene ningún
respaldo si el caché desaparece.

## Descargar el avatar como JPG

`AvatarCreatorResult.imageBytes` es un PNG (ver "5. Guardar" más arriba). Si
el canal necesita entregarle al usuario una imagen descargable en JPG —más
liviana, más compatible con flujos de "compartir" o "subir foto" que esperan
ese formato—, `AvatarCreatorResult` tiene un método para eso:

```dart
final jpgBytes = await result.toJpg(); // Uint8List, listo para escribir/compartir
```

`toJpg()` reutiliza el mismo `imageBytes` ya generado (no vuelve a tocar el
`RepaintBoundary` ni la pantalla): decodifica ese PNG y lo vuelve a codificar
como JPG. Dos parámetros opcionales:

* `backgroundColor` (blanco por defecto): JPG no soporta transparencia, y el
  PNG del avatar **sí** tiene zonas transparentes (las esquinas fuera del
  círculo, recortadas con `ClipOval` — ver `AvatarPreview`). `toJpg()`
  "aplana" esas zonas sobre este color antes de codificar, para que no
  queden negras (el resultado por defecto de la mayoría de decodificadores
  de JPG frente a un canal alfa que no entienden).
* `quality` (92 por defecto): calidad de compresión JPG, de 0 a 100.

Igual que con `imageBytes`, generar los bytes es responsabilidad de la
librería; **escribirlos a un archivo, subirlos o compartirlos es
responsabilidad del canal**. `example/lib/main.dart` (función
`_downloadAvatarAsJpg`) muestra el paso que falta para que sea una imagen
descargable de verdad:

```dart
Future<String> _downloadAvatarAsJpg(AvatarCreatorResult result) async {
  final jpgBytes = await result.toJpg();
  final directory = await getApplicationDocumentsDirectory(); // package:path_provider
  final file = File('${directory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await file.writeAsBytes(jpgBytes);
  return file.path;
}
```

En la app de ejemplo esto se llama desde `CachedImageAvatarCard` (la
Opción B de la sección anterior) justo después de guardar el avatar, y
muestra la ruta del archivo en un `SnackBar`.

## Widget de pantalla de inicio (iOS y Android)

Esto es distinto a todo lo anterior: no es un `Widget` de Flutter, sino un
widget *nativo* de pantalla de inicio (el tipo de widget redimensionable de
la galería de iOS/Android, como el "Pila inteligente" de iOS) que muestra el
último avatar guardado.

**Por qué esto vive en `example/` y no en `avatar_flutter`.** Un widget de
pantalla de inicio depende del bundle ID, del App Group y del ícono de cada
app — es, por definición, responsabilidad del canal, el mismo principio que
ya rige el resto de este README ("¿Qué es responsabilidad de la librería y
qué es responsabilidad del canal?"). `avatar_flutter` solo pone a
disposición `AvatarCreatorResult.imageBytes`; armar el widget nativo con eso
le toca a cada canal. Por eso todo lo de esta sección vive dentro de
`example/`, como referencia que cada canal adapta a su propio bundle ID.

**Limitación importante:** el código de esta sección no se compiló ni se
corrió — se escribió sin Xcode, sin Android Studio y sin el SDK de Flutter
instalados. Antes de darlo por bueno hay que abrir el proyecto con esas
herramientas y seguir los pasos de abajo.

### Cómo fluyen los datos

1. El canal guarda el avatar con `result.imageBytes` (ver `_edit` en
   `CachedImageAvatarCard`, `example/lib/main.dart` — la Opción B de "Dos
   formas de orquestar la imagen del avatar").
2. Justo después, `AvatarHomeWidgetSync.sync(result.imageBytes)`
   (`example/lib/avatar_home_widget_sync.dart`) codifica ese PNG en base64 y
   lo guarda con el paquete [`home_widget`](https://pub.dev/packages/home_widget)
   bajo la llave `avatar_widget_image_base64`, en el almacenamiento que
   comparten la app y el widget: `UserDefaults(suiteName:)` del App Group en
   iOS, `SharedPreferences` en Android (ahí no hace falta App Group: el
   widget corre en el mismo paquete que la app).
3. `HomeWidget.updateWidget(iOSName: "AvatarWidget", androidName:
   "AvatarWidgetProvider")` le avisa a cada plataforma que recargue el
   widget.
4. Si algo de esto falla (por ejemplo, porque todavía no se configuró el
   App Group o el `AppWidgetProvider`), `AvatarHomeWidgetSync.sync` lo
   atrapa y solo lo imprime en consola — no debe tumbar el guardado normal
   del avatar.

Los tres nombres que tienen que coincidir exactamente entre Dart y el
código nativo (`iosAppGroupId`, `iosWidgetKind`/`kind`,
`androidProviderName`) están documentados como constantes, comentadas, en
`avatar_home_widget_sync.dart`.

### iOS: crear el target de Widget Extension

Los archivos Swift ya están escritos en `example/ios/AvatarWidget/`
(`AvatarWidgetBundle.swift`, `AvatarWidget.swift`, `AvatarWidgetView.swift`,
`Info.plist`, `AvatarWidget.entitlements`) — lo que falta es crear el target
en Xcode y sumarlos ahí, porque eso requiere el editor de proyecto de Xcode
(no se puede hacer editando `project.pbxproj` a mano de forma segura):

1. Abrí `example/ios/Runner.xcworkspace` en Xcode.
2. **File > New > Target… > Widget Extension**. Nombre: `AvatarWidget`.
   Desmarcá "Include Configuration Intent" (este widget no tiene
   configuración). Cuando Xcode pregunte si activar el nuevo esquema,
   aceptá.
3. Xcode crea un grupo `AvatarWidget/` con archivos de ejemplo
   (`AvatarWidgetBundle.swift`, etc.) — borralos y arrastrá en su lugar los
   4 archivos Swift + `Info.plist` que ya están en
   `example/ios/AvatarWidget/` (destildá "Copy items if needed" si Xcode
   los ofrece copiar; ya están en la carpeta correcta).
4. Seleccioná el target **Runner** > pestaña **Signing & Capabilities** >
   **+ Capability** > **App Groups** > creá un grupo nuevo, por ejemplo
   `group.<tu-bundle-id>.avatarwidget`. Repetí en el target **AvatarWidget**
   con el **mismo** grupo. Esto reemplaza a los `.entitlements` de
   referencia que ya están en el repo (`Runner/Runner.entitlements`,
   `AvatarWidget/AvatarWidget.entitlements`) — Xcode los regenera y los
   asocia solo al activar la capability así.
5. Actualizá el App Group ID en tres lugares para que coincidan con el que
   creaste en el paso 4: `AvatarHomeWidgetSync.iosAppGroupId` (Dart) y la
   constante `appGroupId` en `AvatarWidget.swift`.
6. Corré el target **AvatarWidget** en el simulador (o el target `Runner`
   y agregá el widget manualmente desde la galería, mantenido presionado en
   el Home). Guardá un avatar en la app para ver que el widget se actualiza.

### Android: agregar la plataforma y el `AppWidgetProvider`

`example/` todavía no tiene carpeta `android/` — hay que generarla primero
con las herramientas de Flutter (no a mano, para no desalinear versiones de
Gradle/AGP con las que espera el SDK instalado):

1. Desde `example/`: `flutter create --platforms=android .`
2. Anotá el `applicationId` que quedó en
   `android/app/build.gradle` (o `build.gradle.kts`).
3. Copiá los archivos de `example/android_widget_reference/` al árbol
   generado:
   - `app/src/main/kotlin/.../AvatarWidgetProvider.kt` → la carpeta de
     Kotlin que coincide con tu `applicationId` (ajustá también la línea
     `package` del archivo).
   - `app/src/main/res/layout/avatar_widget.xml` → mismo path.
   - `app/src/main/res/xml/avatar_widget_info.xml` → mismo path.
4. Copiá el `<receiver>` de `AndroidManifest_snippet.xml` dentro de la
   etiqueta `<application>` de `android/app/src/main/AndroidManifest.xml`.
5. Corré `flutter run` en un emulador/dispositivo Android, mantené
   presionado el Home y agregá el widget "Mi avatar" desde la galería.
   Guardá un avatar en la app para ver que se actualiza.

### Tamaños soportados

| Tamaño | iOS | Android |
| --- | --- | --- |
| Chico | `.systemSmall`: solo el avatar | `minWidth`/`minHeight` (80dp): solo el avatar |
| Mediano/grande | `.systemMedium`/`.systemLarge`: avatar + "Tu avatar" + "Toca para editar" | al agrandarlo por encima de `CAPTION_MIN_WIDTH_DP`: mismo texto |

Las tres variantes de iOS llevan un `widgetURL` placeholder
(`avatarflutterexample://avatar`); `avatar_flutter` no define un esquema de
deep link propio, así que cada canal debe registrar el suyo y manejarlo
donde abre el editor (`_edit` en `CachedImageAvatarCard`).

## Desarrollo

```
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter run
```
