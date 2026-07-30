import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';

/// Galeria de ejemplos de personalizacion de `avatar_flutter`.
///
/// Este archivo es **codigo del canal, no de la libreria** (igual que
/// `main.dart`): existe para mostrar, con casos concretos y ejecutables, que
/// tan lejos puede llegar un canal personalizando la experiencia sin tocar
/// el paquete. Cada tarjeta de esta pantalla abre
/// [AvatarCreatorScreen.push] con una [AvatarCreatorConfig] distinta.
class CustomizationGalleryScreen extends StatelessWidget {
  const CustomizationGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejemplos de personalizacion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoCard(
            title: '1. Por defecto',
            description: 'AvatarCreatorConfig() sin ningun parametro: catalogo '
                'oficial, 2 columnas, alturas 249/160, textos por defecto. '
                'Es lo que obtiene un canal que no personaliza nada.',
            onOpen: () => _openDemo(context, const AvatarCreatorConfig()),
          ),
          _DemoCard(
            title: '2. Personalizacion completa (interactiva)',
            description: 'Abre un formulario donde puedes cambiar en vivo cada '
                'parametro de AvatarCreatorConfig (alturas, columnas del '
                'grid, maximos, textos) y despues abrir el creador con esos '
                'valores exactos.',
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaygroundScreen()),
            ),
          ),
          _DemoCard(
            title: '3. Catalogo reducido - 2 categorias',
            description:
                'Un canal que solo necesita "Vestuario" y "Color de fondo" '
                'puede pasar exactamente esas dos categorias en '
                'AvatarCreatorConfig.categories; el resto del catalogo '
                'oficial simplemente no se usa.',
            onOpen: () => _openDemo(context, _twoCategoriesConfig()),
          ),
          _DemoCard(
            title: '4. Catalogo extendido - 6 categorias',
            description:
                'Las 5 categorias oficiales mas "Insignia", una categoria '
                'que este canal agrego por su cuenta (con su propio SVG, '
                'empaquetado en esta app de ejemplo, no en avatar_flutter).',
            onOpen: () => _openDemo(context, _sixCategoriesConfig()),
          ),
          _DemoCard(
            title: '5. Categoria que la libreria no contempla',
            description:
                'Un catalogo reducido (Vestuario, Cabello, Color de fondo) '
                'con "Insignia" insertada en medio, para demostrar que una '
                'categoria propia del canal se integra en cualquier '
                'posicion sin romper nada.',
            onOpen: () => _openDemo(context, _uncontemplatedCategoryConfig()),
          ),
          _DemoCard(
            title: '6. Editar un avatar existente',
            description:
                'AvatarCreatorConfig.initialSelection ya resuelto con una '
                'seleccion previa (como si viniera de SharedPreferences): '
                'el creador abre directo mostrando esas opciones elegidas, '
                'no las primeras de cada categoria.',
            onOpen: () => _openDemo(context, _editExistingConfig()),
          ),
          _DemoCard(
            title: '7. Callbacks de analitica/eventos',
            description:
                'onView, onSave, onSaveSuccess, onSaveError y onCancel '
                'conectados a SnackBars visibles, para ver exactamente '
                'cuando se dispara cada uno durante una sesion real.',
            onOpen: () => _openDemo(context, _callbacksConfig(context)),
          ),
        ],
      ),
    );
  }
}

/// Abre el creador con [config] y muestra el resultado (guardado o
/// cancelado) en un SnackBar, para que las demos sean visibles sin tener que
/// inspeccionar la consola.
Future<void> _openDemo(BuildContext context, AvatarCreatorConfig config) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await AvatarCreatorScreen.push(context, config: config);
  if (result is AvatarCreatorResult) {
    messenger.showSnackBar(
      SnackBar(content: Text('Guardado: ${result.selection}')),
    );
  } else {
    messenger
        .showSnackBar(const SnackBar(content: Text('Cancelado, sin guardar')));
  }
}

/// La categoria "Insignia": un ejemplo de categoria que **no** existe en
/// [defaultAvatarCatalog] y que este canal agrego por su cuenta. Sus SVGs
/// viven en `example/assets/badge/`, declarados en el `pubspec.yaml` de esta
/// app de ejemplo (no en el de `avatar_flutter`) — por eso
/// [AvatarOption.assetPackage] se deja en `null`: le dice a `flutter_svg`
/// que busque el asset en el bundle de esta app, no dentro del paquete.
AvatarLayerCategory _badgeCategory() {
  return AvatarLayerCategory(
    id: 'badge',
    label: 'Insignia',
    icon: Icons.military_tech_outlined,
    kind: AvatarCategoryKind.layer,
    options: const [
      AvatarOption.layer(
        id: '1',
        assetPath: 'assets/badge/insignia_1.svg',
        // assetPackage: null (por defecto) -> se resuelve desde el bundle
        // de esta app de ejemplo, no desde avatar_flutter.
        semanticLabel: 'Insignia 1',
      ),
      AvatarOption.layer(
        id: '2',
        assetPath: 'assets/badge/insignia_2.svg',
        semanticLabel: 'Insignia 2',
      ),
    ],
  );
}

AvatarCreatorConfig _twoCategoriesConfig() {
  final catalog = defaultAvatarCatalog();
  return AvatarCreatorConfig(
    title: 'Avatar (2 categorias)',
    categories: [
      catalog.firstWhere((c) => c.id == 'body'),
      catalog.firstWhere((c) => c.id == 'background'),
    ],
  );
}

AvatarCreatorConfig _sixCategoriesConfig() {
  return AvatarCreatorConfig(
    title: 'Avatar (6 categorias)',
    categories: [...defaultAvatarCatalog(), _badgeCategory()],
  );
}

AvatarCreatorConfig _uncontemplatedCategoryConfig() {
  final catalog = defaultAvatarCatalog();
  return AvatarCreatorConfig(
    title: 'Avatar (con categoria propia)',
    categories: [
      catalog.firstWhere((c) => c.id == 'body'),
      catalog.firstWhere((c) => c.id == 'hair'),
      _badgeCategory(),
      catalog.firstWhere((c) => c.id == 'background'),
    ],
  );
}

AvatarCreatorConfig _editExistingConfig() {
  // Simula una seleccion guardada previamente (como si viniera de
  // SharedPreferences, ver example/lib/main.dart): el creador debe abrir
  // mostrando exactamente estas opciones, no las primeras de cada
  // categoria.
  return AvatarCreatorConfig(
    title: 'Editar avatar existente',
    initialSelection: Future.value(const {
      'body': '3',
      'hair': '2',
      'hair_color': '4',
      'face': '3',
      'face_color': '2',
      'background': 'blue',
    }),
  );
}

AvatarCreatorConfig _callbacksConfig(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  void toast(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  return AvatarCreatorConfig(
    title: 'Avatar (con callbacks)',
    onView: () => toast('onView: el usuario ya esta viendo el creador'),
    onSave: () => toast('onSave: se toco "Guardar"'),
    onSaveSuccess: (result) =>
        toast('onSaveSuccess: ${result.selection.length} categorias guardadas'),
    onSaveError: (error) => toast('onSaveError: $error'),
    onCancel: () => toast('onCancel: se cerro sin guardar'),
  );
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.onOpen,
  });

  final String title;
  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

/// Formulario interactivo que expone **todos** los parametros visuales de
/// [AvatarCreatorConfig] (mas alla de categories/initialSelection, que ya
/// tienen sus propias demos): alturas del preview, columnas del grid,
/// maximos por categoria, y los textos de header/footer. Sirve para que
/// alguien nuevo en el paquete vea, sin leer codigo, el efecto de cada
/// parametro antes de abrir el creador de verdad.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  double _expandedHeight = 249;
  double _collapsedHeight = 160;
  int _gridCrossAxisCount = 2;
  int _maxGridOptions = 12;
  int _maxRowOptions = 6;
  final _titleController = TextEditingController(text: 'Crear avatar');
  final _saveButtonController = TextEditingController(text: 'Guardar');

  @override
  void dispose() {
    _titleController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  AvatarCreatorConfig _buildConfig() {
    return AvatarCreatorConfig(
      title: _titleController.text,
      saveButtonText: _saveButtonController.text,
      previewExpandedHeight: _expandedHeight,
      previewCollapsedHeight: _collapsedHeight,
      gridCrossAxisCount: _gridCrossAxisCount,
      maxGridOptions: _maxGridOptions,
      maxRowOptions: _maxRowOptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalizacion completa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titulo del header'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _saveButtonController,
            decoration:
                const InputDecoration(labelText: 'Texto del boton Guardar'),
          ),
          const SizedBox(height: 24),
          _SliderRow(
            label: 'Alto expandido del preview',
            value: _expandedHeight,
            min: _collapsedHeight,
            max: 420,
            onChanged: (v) => setState(() => _expandedHeight = v),
          ),
          _SliderRow(
            label: 'Alto encogido del preview',
            value: _collapsedHeight,
            min: 60,
            max: _expandedHeight,
            onChanged: (v) => setState(() => _collapsedHeight = v),
          ),
          _SliderRow(
            label: 'Columnas del grid',
            value: _gridCrossAxisCount.toDouble(),
            min: 2,
            max: 5,
            divisions: 3,
            onChanged: (v) => setState(() => _gridCrossAxisCount = v.round()),
          ),
          _SliderRow(
            label: 'Maximo de opciones en el grid',
            value: _maxGridOptions.toDouble(),
            min: 3,
            max: 16,
            divisions: 13,
            onChanged: (v) => setState(() => _maxGridOptions = v.round()),
          ),
          _SliderRow(
            label: 'Maximo de opciones en la fila de color',
            value: _maxRowOptions.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (v) => setState(() => _maxRowOptions = v.round()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _openDemo(context, _buildConfig()),
            child: const Text('Abrir el creador con esta configuracion'),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
