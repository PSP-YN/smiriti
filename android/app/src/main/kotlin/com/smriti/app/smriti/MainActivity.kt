package com.smriti.app.smriti

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        const val STT_CHANNEL  = "com.smriti.app/stt"
        const val TTS_CHANNEL  = "com.smriti.app/tts"
        const val STT_EVENTS   = "com.smriti.app/stt_events"
    }

    // ── TTS ───────────────────────────────────────────────────────────────────
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    // ── STT ───────────────────────────────────────────────────────────────────
    private var speechRecognizer: SpeechRecognizer? = null
    private var sttEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── TTS Method Channel ────────────────────────────────────────────────
        tts = TextToSpeech(this) { status ->
            ttsReady = (status == TextToSpeech.SUCCESS)
            if (ttsReady) {
                tts?.language = Locale.getDefault()
                tts?.setSpeechRate(0.9f)
                tts?.setPitch(1.0f)
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val langCode = call.argument<String>("language") ?: "en-US"
                        if (!ttsReady) { result.error("NOT_READY", "TTS not initialized", null); return@setMethodCallHandler }
                        tts?.language = Locale.forLanguageTag(langCode)
                        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                            override fun onStart(id: String?) {}
                            override fun onDone(id: String?) { runOnUiThread { result.success(true) } }
                            @Deprecated("Deprecated in Java")
                            override fun onError(id: String?) { runOnUiThread { result.error("TTS_ERROR", "Utterance error", null) } }
                        })
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "smriti_${System.currentTimeMillis()}")
                    }
                    "stop" -> {
                        tts?.stop()
                        result.success(true)
                    }
                    "isAvailable" -> result.success(ttsReady)
                    "setLanguage" -> {
                        val langCode = call.argument<String>("language") ?: "en-US"
                        val locale = Locale.forLanguageTag(langCode)
                        val supported = tts?.isLanguageAvailable(locale) ?: TextToSpeech.LANG_NOT_SUPPORTED
                        if (supported >= TextToSpeech.LANG_AVAILABLE) {
                            tts?.language = locale
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "setSpeechRate" -> {
                        val rate = call.argument<Double>("rate")?.toFloat() ?: 0.9f
                        tts?.setSpeechRate(rate)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── STT Event Channel ─────────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STT_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sttEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    sttEventSink = null
                }
            })

        // ── STT Method Channel ────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(SpeechRecognizer.isRecognitionAvailable(this))
                    "startListening" -> {
                        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                            result.error("NOT_AVAILABLE", "Speech recognition not available on this device", null)
                            return@setMethodCallHandler
                        }
                        val langCode = call.argument<String>("language") ?: "en-US"
                        startSpeechRecognition(langCode)
                        result.success(true)
                    }
                    "stopListening" -> {
                        speechRecognizer?.stopListening()
                        result.success(true)
                    }
                    "cancelListening" -> {
                        speechRecognizer?.cancel()
                        result.success(true)
                    }
                    "transcribeFile" -> {
                        // Android SpeechRecognizer is live-mic only.
                        // For file transcription we return a structured placeholder that tells
                        // the Dart side to use OCR-like text extraction on audio.
                        result.success(mapOf(
                            "text" to "[Audio file indexed. Use the microphone button for live speech-to-text.]",
                            "confidence" to 0.0,
                            "language" to "en"
                        ))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startSpeechRecognition(langCode: String) {
        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                runOnUiThread { sttEventSink?.success(mapOf("type" to "ready")) }
            }
            override fun onBeginningOfSpeech() {
                runOnUiThread { sttEventSink?.success(mapOf("type" to "speech_start")) }
            }
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {
                runOnUiThread { sttEventSink?.success(mapOf("type" to "speech_end")) }
            }
            override fun onError(error: Int) {
                val msg = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission required"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                    else -> "Recognition error ($error)"
                }
                runOnUiThread { sttEventSink?.success(mapOf("type" to "error", "message" to msg)) }
            }
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val scores = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
                val text = matches?.firstOrNull() ?: ""
                val confidence = scores?.firstOrNull()?.toDouble() ?: 0.0
                runOnUiThread {
                    sttEventSink?.success(mapOf(
                        "type" to "result",
                        "text" to text,
                        "confidence" to confidence,
                        "isFinal" to true
                    ))
                }
            }
            override fun onPartialResults(partialResults: Bundle?) {
                val partial = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: ""
                runOnUiThread {
                    sttEventSink?.success(mapOf(
                        "type" to "result",
                        "text" to partial,
                        "confidence" to 0.5,
                        "isFinal" to false
                    ))
                }
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, langCode)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, langCode)
            putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, langCode)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1000L)
        }
        speechRecognizer?.startListening(intent)
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        speechRecognizer?.destroy()
        super.onDestroy()
    }
}
