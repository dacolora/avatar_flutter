import WidgetKit
import SwiftUI

/// Layout por tamaño:
/// - `.systemSmall`: solo el avatar, sin texto (no entra nada más).
/// - `.systemMedium` / `.systemLarge`: avatar + "Tu avatar" + hint de que
///   se puede tocar para editar.
///
/// El `widgetURL` en las tres variantes es un placeholder
/// (`avatarflutterexample://avatar`): `avatar_flutter` no define un
/// esquema de deep link propio, así que cada canal debe registrar el suyo
/// (Info.plist -> `CFBundleURLTypes`) y manejarlo donde abre el editor
/// (`_edit` en `CachedImageAvatarCard`, `main.dart`).
struct AvatarWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AvatarEntry

    var body: some View {
        switch family {
        case .systemSmall:
            avatarImage
                .clipShape(Circle())
                .padding(12)
                .widgetURL(URL(string: "avatarflutterexample://avatar"))
        default:
            HStack(spacing: 12) {
                avatarImage
                    .clipShape(Circle())
                    .frame(
                        width: family == .systemLarge ? 96 : 64,
                        height: family == .systemLarge ? 96 : 64
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu avatar")
                        .font(.headline)
                    Text("Toca para editar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .widgetURL(URL(string: "avatarflutterexample://avatar"))
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let image = entry.avatarImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }
}
