package com.example.quranglow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

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
                setTextViewText(R.id.widget_streak_value, streakValue)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
