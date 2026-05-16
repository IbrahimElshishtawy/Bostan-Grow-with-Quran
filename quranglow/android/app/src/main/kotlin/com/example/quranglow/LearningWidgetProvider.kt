package com.example.quranglow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri

class LearningWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.learning_widget_layout).apply {
                val streakValue = widgetData.getString("streak_value", "0")
                val levelValue = widgetData.getString("level_value", "1")
                val stationTitle = widgetData.getString("station_title", "الورد القرآني")
                
                setTextViewText(R.id.widget_streak_value, "🔥 $streakValue")
                setTextViewText(R.id.widget_level, "مستوى $levelValue")
                setTextViewText(R.id.widget_station_title, stationTitle)

                // Update Alphas for tasks (0.3 for incomplete, 1.0f for complete)
                val listenDone = widgetData.getString("task_listen", "0") == "1"
                val readDone = widgetData.getString("task_read", "0") == "1"
                val writeDone = widgetData.getString("task_write", "0") == "1"
                val memorizeDone = widgetData.getString("task_memorize", "0") == "1"
                val quizDone = widgetData.getString("task_quiz", "0") == "1"

                // Use setTextColor with ARGB to handle transparency safely on all Android versions
                val activeColor = 0xFFFFFFFF.toInt() // 100% opacity
                val inactiveColor = 0x4DFFFFFF.toInt() // ~30% opacity

                setInt(R.id.task_listen, "setTextColor", if (listenDone) activeColor else inactiveColor)
                setInt(R.id.task_read, "setTextColor", if (readDone) activeColor else inactiveColor)
                setInt(R.id.task_write, "setTextColor", if (writeDone) activeColor else inactiveColor)
                setInt(R.id.task_memorize, "setTextColor", if (memorizeDone) activeColor else inactiveColor)
                setInt(R.id.task_quiz, "setTextColor", if (quizDone) activeColor else inactiveColor)

                // Add PendingIntent to open the app when the widget is tapped
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                
                // Use FLAG_IMMUTABLE as per modern Android requirements
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
