package com.fload.attribution.flutter

import com.fload.attribution.FloadLogLevel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals

class FloadAttributionPluginTest {
    @Test
    fun `options default to Fload's endpoint and the warning level`() {
        val options = FloadAttributionPlugin.options(null, null)
        assertEquals("https://ingest.fload.com", options.endpoint)
        assertEquals(FloadLogLevel.WARNING, options.logLevel)
    }

    @Test
    fun `options carry the endpoint and level the app gives`() {
        val options = FloadAttributionPlugin.options("http://10.0.2.2:3999", "debug")
        assertEquals("http://10.0.2.2:3999", options.endpoint)
        assertEquals(FloadLogLevel.DEBUG, options.logLevel)
    }

    @Test
    fun `every Dart log level maps to the SDK's`() {
        val expected = mapOf(
            "none" to FloadLogLevel.NONE,
            "error" to FloadLogLevel.ERROR,
            "warning" to FloadLogLevel.WARNING,
            "info" to FloadLogLevel.INFO,
            "debug" to FloadLogLevel.DEBUG,
        )
        expected.forEach { (name, level) -> assertEquals(level, FloadAttributionPlugin.level(name)) }
    }

    @Test
    fun `configure without a key is an error, not a crash`() {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        FloadAttributionPlugin().onMethodCall(MethodCall("configure", mapOf("logLevel" to "debug")), result)
        Mockito.verify(result).error("bad_arguments", "configure needs a key", null)
    }

    @Test
    fun `an unknown method is not implemented`() {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        FloadAttributionPlugin().onMethodCall(MethodCall("track", null), result)
        Mockito.verify(result).notImplemented()
    }
}
