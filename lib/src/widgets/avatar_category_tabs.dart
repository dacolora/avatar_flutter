import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/avatar_creator_controller.dart';

/// Fila horizontal de tabs de categoría (#4 Categorías + #5 Card container
/// de la especificación): un botón circular con icono por cada categoría
/// del catálogo, donde solo uno puede estar activo a la vez.
///
/// Es un `StatelessWidget` — es decir, no guarda ningún estado propio —
/// porque toda la información que necesita (cuáles son las categorías, cuál
/// está activa) la lee en tiempo real desde el [AvatarCreatorController] con
/// `context.watch<...>()`. Cuando el usuario toca un tab y el controlador
/// llama a `notifyListeners()`, este widget se reconstruye automáticamente
/// con el nuevo tab marcado como activo.
class AvatarCategoryTabs extends StatelessWidget {
  const AvatarCategoryTabs({super.key});

  static const Color _dividerColor = Color(0xFFD9DADD); // token border/default

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarCreatorController>();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
      ),
      // `ShaderMask` aplica un efecto visual (definido por `shaderCallback`)
      // sobre su hijo. Aquí se usa para crear el "gradiente de desvanecido"
      // en los bordes izquierdo y derecho de la fila de tabs: el
      // `LinearGradient` va de transparente a blanco opaco y de vuelta a
      // transparente, y `BlendMode.dstIn` hace que ese gradiente controle la
      // opacidad del contenido de abajo en vez de dibujarse como un color
      // encima. El resultado es que, cuando hay más tabs de los que caben en
      // pantalla, los que quedan parcialmente ocultos en los bordes se ven
      // "desvanecidos" en vez de cortados abruptamente — una pista visual de
      // que se puede seguir deslizando.
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 0.03, 0.97, 1],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              for (final category in controller.categories) ...[
                _CategoryTabButton(
                  isSelected: category.id == controller.activeCategoryId,
                  icon: category.icon,
                  label: category.label,
                  onPressed: () => controller.selectCategory(category.id),
                ),
                const SizedBox(width: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Un único botón circular de tab, con su icono y su estado
/// seleccionado/no-seleccionado.
///
/// Está declarado como clase privada (el nombre empieza con `_`, una
/// convención de Dart que hace que solo sea visible dentro de este archivo)
/// porque no tiene sentido usarlo fuera de [AvatarCategoryTabs]: es un
/// detalle de implementación de cómo se dibuja cada tab, no una pieza que el
/// canal necesite instanciar por su cuenta.
class _CategoryTabButton extends StatelessWidget {
  const _CategoryTabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // `Semantics` no cambia nada visualmente: describe este widget para
    // tecnologías de accesibilidad (lectores de pantalla como VoiceOver o
    // TalkBack), indicando que es un botón (`button: true`), si está
    // seleccionado (`selected: isSelected`) y qué texto debe anunciarse
    // (`label`). Sin esto, un lector de pantalla solo vería un icono sin
    // contexto.
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
          ),
          child: Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
