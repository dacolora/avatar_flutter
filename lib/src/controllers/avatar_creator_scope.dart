import 'package:flutter/widgets.dart';

import 'avatar_creator_controller.dart';

/// Comparte una única instancia de [AvatarCreatorController] con todos los
/// widgets descendientes, **sin depender del paquete `provider`**.
///
/// ### ¿Por qué no usar `provider`?
/// El paquete `provider` (con `ChangeNotifierProvider` y `Consumer`) es una
/// forma muy popular de resolver este mismo problema, pero es una
/// dependencia externa: obliga a que cualquier app que use este paquete
/// también termine con `provider` en su árbol de dependencias, con la
/// versión que este paquete elija. Algunos canales no pueden asumir esa
/// dependencia (por ejemplo, porque ya usan otra versión incompatible, o
/// porque su arquitectura no lo permite). Por eso `avatar_flutter` resuelve
/// el mismo problema usando únicamente piezas que **ya vienen incluidas en
/// el SDK de Flutter**: [ChangeNotifier] e [InheritedNotifier], ambas parte
/// de `package:flutter`, no de un paquete de terceros.
///
/// ### ¿Cómo funciona un [InheritedNotifier]?
/// [InheritedNotifier] es una clase que ya trae Flutter (en
/// `widgets/inherited_notifier.dart`) pensada exactamente para este caso:
/// "quiero que un objeto [Listenable] (como un [ChangeNotifier]) esté
/// disponible para cualquier descendiente del árbol de widgets, y que esos
/// descendientes se reconstruyan automáticamente cada vez que ese objeto
/// llame a `notifyListeners()`". Es, en esencia, el mismo mecanismo que usa
/// `ChangeNotifierProvider` + `Consumer`/`context.watch` por debajo, sin la
/// capa adicional del paquete `provider`.
///
/// Un widget descendiente accede al controlador llamando a
/// `AvatarCreatorScope.of(context)`. Esa llamada usa
/// `context.dependOnInheritedWidgetOfExactType<AvatarCreatorScope>()`, que
/// hace dos cosas a la vez: (1) devuelve la instancia actual del
/// [AvatarCreatorScope] más cercana hacia arriba en el árbol, y (2) registra
/// a `context` como "dependiente" de ese widget, de forma que Flutter sepa
/// que debe reconstruirlo cuando el [AvatarCreatorController] notifique un
/// cambio.
class AvatarCreatorScope extends InheritedNotifier<AvatarCreatorController> {
  /// Envuelve [child] exponiéndole [controller] a todos sus descendientes.
  const AvatarCreatorScope({
    required AvatarCreatorController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Busca el [AvatarCreatorController] más cercano hacia arriba desde
  /// [context] y suscribe a `context` para reconstruirse cuando ese
  /// controlador cambie.
  ///
  /// Lanza un error de aserción en modo debug si se llama fuera de un árbol
  /// que tenga un [AvatarCreatorScope] como ancestro — algo que no debería
  /// pasar dentro de este paquete, ya que [AvatarCreatorScreen] siempre
  /// coloca uno antes de construir el resto de la pantalla.
  static AvatarCreatorController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AvatarCreatorScope>();
    assert(
      scope != null,
      'AvatarCreatorScope.of() fue llamado fuera del árbol de AvatarCreatorScreen.',
    );
    return scope!.notifier!;
  }
}
