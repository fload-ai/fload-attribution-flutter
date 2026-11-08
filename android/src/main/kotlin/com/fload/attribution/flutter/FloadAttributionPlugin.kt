package com.fload.attribution.flutter

import android.content.Context
import com.fload.attribution.Fload
import com.fload.attribution.FloadLogLevel
import com.fload.attribution.FloadOptions
import com.fload.attribution.FloadWrapper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The Android half of the plugin: maps channel calls to the Fload Android SDK. */
class FloadAttributionPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val key = call.argument<String>("key")
                val app = context
                if (key == null || app == null) {
                    result.error("bad_arguments", "configure needs a key", null)
                    return
                }
                val options = options(
                    call.argument("endpoint"),
                    call.argument("logLevel"),
                    call.argument("wrapperName"),
                    call.argument("wrapperVersion"),
                )
                Fload.configure(app, key, options)
                result.success(null)
            }
            "setUserId" -> {
                val userId = call.argument<String>("userId")
                if (userId == null) {
                    result.error("bad_arguments", "setUserId needs a userId", null)
                    return
                }
                Fload.setUserId(userId)
                result.success(null)
            }
            "getInstallReference" -> result.success(Fload.installReference)
            else -> result.notImplemented()
        }
    }

    internal companion object {
        const val CHANNEL = "com.fload.attribution"

        /**
         * The SDK's options from the channel's strings. The wrapper (this
         * plugin's name and version, from Dart) goes on every request as `sdk.wrapper`.
         */
        fun options(endpoint: String?, logLevel: String?, wrapperName: String?, wrapperVersion: String?): FloadOptions {
            val level = level(logLevel)
            val wrapper = if (wrapperName != null && wrapperVersion != null) FloadWrapper(wrapperName, wrapperVersion) else null
            return if (endpoint.isNullOrEmpty()) {
                FloadOptions(logLevel = level, wrapper = wrapper)
            } else {
                FloadOptions(endpoint = endpoint, logLevel = level, wrapper = wrapper)
            }
        }

        fun level(name: String?): FloadLogLevel = when (name) {
            "none" -> FloadLogLevel.NONE
            "error" -> FloadLogLevel.ERROR
            "info" -> FloadLogLevel.INFO
            "debug" -> FloadLogLevel.DEBUG
            else -> FloadLogLevel.WARNING
        }
    }
}
