package com.daidai.panel.core.storage

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "theme_preferences")

@Singleton
class ThemePreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private val KEY_THEME_MODE = intPreferencesKey("theme_mode")
        private val KEY_GLASS_MODE = booleanPreferencesKey("glass_mode")
        private val KEY_BG_IMAGE_PATH = stringPreferencesKey("bg_image_path")
        private val KEY_BLUR_INTENSITY = floatPreferencesKey("blur_intensity")
    }

    val themeMode: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_THEME_MODE] ?: 0
    }

    val glassMode: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[KEY_GLASS_MODE] ?: false
    }

    val backgroundImagePath: Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[KEY_BG_IMAGE_PATH]
    }

    val blurIntensity: Flow<Float> = context.dataStore.data.map { prefs ->
        prefs[KEY_BLUR_INTENSITY] ?: 0.5f
    }

    suspend fun setThemeMode(mode: Int) {
        context.dataStore.edit { prefs ->
            prefs[KEY_THEME_MODE] = mode
        }
    }

    suspend fun setGlassMode(enabled: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[KEY_GLASS_MODE] = enabled
        }
    }

    suspend fun setBackgroundImagePath(path: String?) {
        context.dataStore.edit { prefs ->
            if (path != null) {
                prefs[KEY_BG_IMAGE_PATH] = path
            } else {
                prefs.remove(KEY_BG_IMAGE_PATH)
            }
        }
    }

    suspend fun setBlurIntensity(intensity: Float) {
        context.dataStore.edit { prefs ->
            prefs[KEY_BLUR_INTENSITY] = intensity
        }
    }
}
