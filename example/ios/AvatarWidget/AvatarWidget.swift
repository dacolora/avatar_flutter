import WidgetKit
import SwiftUI

/// Debe ser exactamente el mismo App Group que se activa en Xcode para
/// **ambos** targets (Runner y AvatarWidgetExtension) y el mismo valor que
/// `AvatarHomeWidgetSync.iosAppGroupId` en
/// `example/lib/avatar_home_widget_sync.dart`.
private let appGroupId = "group.com.grupobancolombia.avatarwidget"

/// Misma llave que `AvatarHomeWidgetSync.widgetImageKey` en Dart: el PNG
/// del avatar, codificado en base64, guardado por `home_widget` en
/// `UserDefaults(suiteName: appGroupId)`.
private let widgetImageKey = "avatar_widget_image_base64"

struct AvatarEntry: TimelineEntry {
    let date: Date
    let avatarImage: UIImage?
}

struct AvatarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AvatarEntry {
        AvatarEntry(date: Date(), avatarImage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (AvatarEntry) -> Void) {
        completion(AvatarEntry(date: Date(), avatarImage: loadAvatarImage()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AvatarEntry>) -> Void) {
        let entry = AvatarEntry(date: Date(), avatarImage: loadAvatarImage())
        // El widget no cambia solo: se refresca on-demand cuando la app llama
        // `HomeWidget.updateWidget` tras guardar un avatar nuevo (ver
        // `AvatarHomeWidgetSync.sync`), así que una sola entrada sin
        // política de recarga (`.never`) alcanza.
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadAvatarImage() -> UIImage? {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let base64 = defaults.string(forKey: widgetImageKey),
            let data = Data(base64Encoded: base64)
        else {
            return nil
        }
        return UIImage(data: data)
    }
}

struct AvatarWidget: Widget {
    /// Debe coincidir con `AvatarHomeWidgetSync.iosWidgetKind` en Dart:
    /// `HomeWidget.updateWidget(iOSName: ...)` usa este valor para saber a
    /// qué widget avisarle que se refresque.
    let kind: String = "AvatarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AvatarTimelineProvider()) { entry in
            AvatarWidgetView(entry: entry)
        }
        .configurationDisplayName("Mi avatar")
        .description("Muestra el avatar guardado en el perfil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
