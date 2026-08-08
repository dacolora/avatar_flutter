import WidgetKit
import SwiftUI

/// Punto de entrada de la extensión de widgets. Xcode lo genera solo al
/// crear el target "Widget Extension" — este archivo reemplaza a ese
/// generado, dejando un solo widget (`AvatarWidget`) en el bundle.
///
/// Ver README, sección "Widget de pantalla de inicio (iOS y Android)", paso
/// "Crear el target en Xcode", para cómo se agrega este archivo al target.
@main
struct AvatarWidgetBundle: WidgetBundle {
    var body: some Widget {
        AvatarWidget()
    }
}
