package com.example.digital_naam_lekhan

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "sankalp/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "shareImage" -> {

                    val bytes = call.argument<ByteArray>("bytes")
                    val targetPackage = call.argument<String>("packageName")
                    val caption = call.argument<String>("caption")
                        ?: "I completed my Naam Lekhan Sankalp! 🙏"

                    if (bytes == null || targetPackage.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Image bytes or package name missing.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val shareDir = File(cacheDir, "shared_images")
                        shareDir.mkdirs()

                        val imageFile = File(
                            shareDir,
                            "naam_completion_card.png"
                        )

                        imageFile.writeBytes(bytes)

                        val imageUri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            imageFile
                        )

                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, imageUri)
                            putExtra(Intent.EXTRA_TEXT, caption)
                            setPackage(targetPackage)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        startActivity(shareIntent)
                        result.success(true)

                    } catch (e: ActivityNotFoundException) {
                        result.error(
                            "APP_NOT_INSTALLED",
                            "Target app is not installed.",
                            null
                        )
                    } catch (e: Exception) {
                        result.error(
                            "SHARE_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
