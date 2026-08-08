import 'dart:convert';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';

/// Sincroniza el avatar guardado con el widget nativo de pantalla de
/// inicio (WidgetKit en iOS, App Widget en Android).
///
/// Este archivo vive en `example/`, no en la librería `avatar_flutter`:
/// el widget de pantalla de inicio depende del bundle ID / App Group /
/// ícono de cada canal, así que armarlo es responsabilidad del canal, igual
/// que la persistencia con `shared_preferences` en `main.dart` (ver "¿Qué es
/// responsabilidad de la librería y qué es responsabilidad del canal?" en el
/// README).
class AvatarHomeWidgetSync {
  AvatarHomeWidgetSync._();

  /// Debe coincidir con el App Group configurado en Xcode (mismo grupo en
  /// el target de la app y en el de la extensión) — ver README, sección
  /// "Widget de pantalla de inicio". En Android no se usa (ahí el widget
  /// vive en el mismo proceso/paquete que la app, no necesita App Group).
  static const String iosAppGroupId = 'group.com.grupobancolombia.avatarwidget';

  /// Nombre del `kind` declarado en `AvatarWidget.swift` (iOS) y del
  /// `AppWidgetProvider` (`AvatarWidgetProvider`, Android) — debe coincidir
  /// exactamente en ambos lados para que `HomeWidget.updateWidget` los
  /// encuentre.
  static const String iosWidgetKind = 'AvatarWidget';
  static const String androidProviderName = 'AvatarWidgetProvider';

  /// Llave bajo la que se guarda el PNG del avatar, codificado en base64,
  /// en el almacenamiento que comparten la app y el widget (`UserDefaults`
  /// del App Group en iOS, `SharedPreferences` en Android). Se guarda como
  /// texto en vez de como archivo para no depender de la ruta al
  /// contenedor compartido de iOS, que `home_widget` no expone desde Dart.
  static const String widgetImageKey = 'avatar_widget_image_base64';

  /// Escribe `imageBytes` (el mismo PNG de `AvatarCreatorResult.imageBytes`)
  /// en el almacenamiento compartido con el widget y le pide a la
  /// plataforma que lo refresque en la pantalla de inicio.
  ///
  /// Se llama después de guardar el avatar (ver `_openAvatarCreator` en
  /// `main.dart`); si falla —por ejemplo porque el canal todavía no
  /// terminó de configurar el App Group en Xcode o el `AppWidgetProvider`
  /// en Android— no interrumpe el flujo normal de guardado: el widget
  /// nativo es un extra, no algo de lo que dependa el resto de la app.
  static Future<void> sync(Uint8List imageBytes) async {
    try {
      await HomeWidget.setAppGroupId(iosAppGroupId);
      await HomeWidget.saveWidgetData<String>(
        widgetImageKey,
        base64Encode(imageBytes),
      );
      await HomeWidget.updateWidget(
        iOSName: iosWidgetKind,
        androidName: androidProviderName,
      );
    } catch (error) {
      // ignore: avoid_print
      print('AvatarHomeWidgetSync: no se pudo sincronizar el widget ($error)');
    }
  }
}
