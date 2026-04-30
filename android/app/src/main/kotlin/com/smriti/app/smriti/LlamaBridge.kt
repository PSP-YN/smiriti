package com.smriti.app.smriti

import android.util.Log

/**
 * Bridge class for llama.cpp native library.
 * Provides FFI interface for Flutter to perform on-device LLM inference.
 */
class LlamaBridge {
    companion object {
        private const val TAG = "SmritiLLM"
        
        init {
            try {
                System.loadLibrary("llama")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library: ${e.message}")
            }
        }
    }
    
    private var nativeContext: Long = 0
    var isInitialized: Boolean = false
        private set
    
    /**
     * Initialize the LLM with a model file.
     * @param modelPath Absolute path to the GGUF model file
     * @return true if initialization successful
     */
    fun initialize(modelPath: String): Boolean {
        if (isInitialized) {
            Log.w(TAG, "LLM already initialized")
            return true
        }
        
        return try {
            nativeContext = nativeInit(modelPath)
            isInitialized = nativeContext != 0L
            Log.i(TAG, "LLM initialized: $isInitialized")
            isInitialized
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize LLM: ${e.message}")
            false
        }
    }
    
    /**
     * Generate text from a prompt.
     * @param prompt Input prompt text
     * @param maxTokens Maximum tokens to generate
     * @param temperature Sampling temperature (0.0 - 1.0)
     * @param topP Nucleus sampling parameter (0.0 - 1.0)
     * @return Generated text
     */
    fun generate(
        prompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7f,
        topP: Float = 0.9f
    ): String {
        if (!isInitialized || nativeContext == 0L) {
            throw IllegalStateException("LLM not initialized")
        }
        
        return try {
            nativePredict(nativeContext, prompt, maxTokens, temperature, topP)
        } catch (e: Exception) {
            Log.e(TAG, "Generation failed: ${e.message}")
            "Error: ${e.message}"
        }
    }
    
    /**
     * Get model information as JSON string.
     */
    fun getModelInfo(): String {
        if (!isInitialized) {
            return "{}"
        }
        return nativeGetModelInfo(nativeContext)
    }
    
    /**
     * Release resources and free the model.
     */
    fun dispose() {
        if (isInitialized && nativeContext != 0L) {
            nativeFree(nativeContext)
            nativeContext = 0
            isInitialized = false
            Log.i(TAG, "LLM disposed")
        }
    }
    
    // Native methods - implemented in llama_bridge.cpp
    private external fun nativeInit(modelPath: String): Long
    private external fun nativePredict(
        context: Long,
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float
    ): String
    private external fun nativeFree(context: Long)
    private external fun nativeGetModelInfo(context: Long): String
}
