package com.itsash.workout

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.CalendarContract
import android.provider.MediaStore
import android.view.WindowManager
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Channel `com.itsash.workout/platform` (see `lib/platform/platform_channel.dart`):
 * - `beep`: short tone on the alarm stream, for the speed change countdown.
 * - `keepScreenOn(bool)`: window flag while a session or timer runs.
 * - `addToCalendar {title, details, location, begin, end, webUrl}`: opens the
 *   calendar app's new-event screen, or the Google Calendar web form.
 * - `saveImage {png, name}` -> where it was saved: `Pictures/Workout` in the
 *   gallery (Android 10+), or the app's own Pictures folder on older phones.
 * - `shareImage {png, name}`: share sheet through the FileProvider.
 */
class MainActivity : FlutterActivity() {
    private var tone: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "beep" -> {
                    beep()
                    result.success(null)
                }
                "keepScreenOn" -> {
                    if (call.arguments as? Boolean == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "addToCalendar" -> {
                    addToCalendar(
                        title = call.argument<String>("title") ?: "Workout",
                        details = call.argument<String>("details") ?: "",
                        location = call.argument<String>("location") ?: "",
                        begin = call.argument<Number>("begin")?.toLong() ?: System.currentTimeMillis(),
                        end = call.argument<Number>("end")?.toLong() ?: System.currentTimeMillis(),
                        webUrl = call.argument<String>("webUrl"),
                    )
                    result.success(null)
                }
                "saveImage" -> {
                    val png = call.argument<ByteArray>("png")
                    val name = call.argument<String>("name") ?: "workout.png"
                    if (png == null) {
                        result.error("bad_args", "png is missing", null)
                    } else {
                        try {
                            result.success(saveImage(png, name))
                        } catch (e: Exception) {
                            result.error("save_failed", e.message, null)
                        }
                    }
                }
                "shareImage" -> {
                    val png = call.argument<ByteArray>("png")
                    val name = call.argument<String>("name") ?: "workout.png"
                    if (png == null) {
                        result.error("bad_args", "png is missing", null)
                    } else {
                        shareImage(png, name)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun beep() {
        try {
            val t = tone ?: ToneGenerator(AudioManager.STREAM_ALARM, 80).also { tone = it }
            t.startTone(ToneGenerator.TONE_PROP_BEEP, 200)
        } catch (_: RuntimeException) {
            // ToneGenerator can fail when the audio system is busy; skip this beep.
            tone = null
        }
    }

    private fun addToCalendar(title: String, details: String, location: String, begin: Long, end: Long, webUrl: String?) {
        val insert = Intent(Intent.ACTION_INSERT)
            .setData(CalendarContract.Events.CONTENT_URI)
            .putExtra(CalendarContract.Events.TITLE, title)
            .putExtra(CalendarContract.Events.DESCRIPTION, details)
            .putExtra(CalendarContract.Events.EVENT_LOCATION, location)
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, begin)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
        try {
            startActivity(insert)
        } catch (_: ActivityNotFoundException) {
            if (webUrl != null) {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(webUrl)))
                } catch (_: ActivityNotFoundException) {
                }
            }
        }
    }

    private fun saveImage(png: ByteArray, name: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Workout")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore insert failed")
            resolver.openOutputStream(uri)?.use { it.write(png) }
                ?: throw IllegalStateException("Cannot write image")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Pictures/Workout/$name"
        }
        // Android 8-9: no MediaStore RELATIVE_PATH without a storage permission.
        val dir = getExternalFilesDir(Environment.DIRECTORY_PICTURES) ?: filesDir
        val file = File(dir, name)
        file.writeBytes(png)
        return file.absolutePath
    }

    private fun shareImage(png: ByteArray, name: String) {
        val dir = File(cacheDir, "share").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val file = File(dir, name).apply { writeBytes(png) }
        val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
        val send = Intent(Intent.ACTION_SEND)
            .setType("image/png")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = ClipData.newRawUri(name, uri)
        startActivity(Intent.createChooser(send, "Share workout"))
    }

    override fun onDestroy() {
        tone?.release()
        tone = null
        super.onDestroy()
    }

    private companion object {
        const val CHANNEL = "com.itsash.workout/platform"
    }
}
