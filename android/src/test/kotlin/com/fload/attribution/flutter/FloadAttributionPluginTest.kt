package com.fload.attribution.flutter

import com.fload.attribution.FloadLogLevel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class FloadAttributionPluginTest {
    @Test
    fun `options default to Fload's endpoint and the warning level`() {
        val options = FloadAttributionPlugin.options(null, null, null, null)
        assertEquals("https://ingest.fload.com", options.endpoint)
        assertEquals(FloadLogLevel.WARNING, options.logLevel)
    }

    @Test
    fun `options carry the endpoint and level the app gives`() {
        val options = FloadAttributionPlugin.options("http://10.0.2.2:3999", "debug", null, null)
        assertEquals("http://10.0.2.2:3999", options.endpoint)
        assertEquals(FloadLogLevel.DEBUG, options.logLevel)
    }

    @Test
    fun `options name the wrapper and the version Dart sends (FLO-3957)`() {
        val options = FloadAttributionPlugin.options(null, "debug", "flutter", "1.1.0")
        assertEquals("flutter", options.wrapper?.name)
        assertEquals("1.1.0", options.wrapper?.version)
        assertEquals("https://ingest.fload.com", options.endpoint)
        assertEquals(FloadLogLevel.DEBUG, options.logLevel)
    }

    @Test
    fun `options with an endpoint name the wrapper too`() {
        val options = FloadAttributionPlugin.options("http://10.0.2.2:3999", null, "flutter", "1.1.0")
        assertEquals("http://10.0.2.2:3999", options.endpoint)
        assertEquals("flutter", options.wrapper?.name)
        assertEquals("1.1.0", options.wrapper?.version)
    }

    @Test
    fun `options without a wrapper name or version name none`() {
        assertNull(FloadAttributionPlugin.options(null, null, null, null).wrapper)
        assertNull(FloadAttributionPlugin.options(null, null, "flutter", null).wrapper)
        assertNull(FloadAttributionPlugin.options(null, null, null, "1.1.0").wrapper)
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
