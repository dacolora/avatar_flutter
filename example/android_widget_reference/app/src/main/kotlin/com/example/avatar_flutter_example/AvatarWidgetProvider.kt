package com.example.avatar_flutter_example

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews

/**
 * Debe llamarse igual que `AvatarHomeWidgetSync.androidProviderName` en
 * `avatar_home_widget_sync.dart` y estar registrado con ese mismo nombre en
 * `AndroidManifest.xml` (ver README, "Widget de pantalla de inicio").
 *
 * Ajustá el `package` de este archivo (y la carpeta que lo contiene) al
 * `applicationId` real de `example/android/app/build.gradle` una vez que
 * corras `flutter create --platforms=android .`.
 */
class AvatarWidgetProvider : AppWidgetProvider() {

    companion object {
        // Misma llave que `AvatarHomeWidgetSync.widgetImageKey` en Dart.
        private const val WIDGET_IMAGE_KEY = "avatar_widget_image_base64"

        // Nombre del archivo de SharedPreferences donde el plugin
        // `home_widget` guarda lo que la app le pasa con
        // `HomeWidget.saveWidgetData`.
        private const val PREFS_NAME = "HomeWidgetPreferences"

        // Debajo de este ancho (dp) el widget no tiene lugar para el texto,
        // así que solo se muestra el avatar — el equivalente Android de
        // `.systemSmall` en iOS.
        private const val CAPTION_MIN_WIDTH_DP = 110
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val base64 = prefs.getString(WIDGET_IMAGE_KEY, null)

        val views = RemoteViews(context.packageName, R.layout.avatar_widget)

        if (base64 != null) {
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            views.setImageViewBitmap(R.id.avatar_widget_image, bitmap)
        } else {
            views.setImageViewResource(
                R.id.avatar_widget_image,
                android.R.drawable.ic_menu_gallery
            )
        }

        val minWidth = appWidgetManager
            .getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        views.setViewVisibility(
            R.id.avatar_widget_caption,
            if (minWidth >= CAPTION_MIN_WIDTH_DP) android.view.View.VISIBLE else android.view.View.GONE
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
