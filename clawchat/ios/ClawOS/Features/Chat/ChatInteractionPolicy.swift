enum ChatAutoScrollTrigger {
    case renderedMessagesChanged
    case previewAssistantMessageChanged
    case streamingTextChanged
    case typingStateChanged
    case inputFocusChanged
    case keyboardFrameChanged
}

enum ChatAutoScrollPolicy {
    static func shouldScrollToBottom(
        for trigger: ChatAutoScrollTrigger,
        isInputFocused: Bool = false
    ) -> Bool {
        switch trigger {
        case .renderedMessagesChanged,
                .previewAssistantMessageChanged,
                .streamingTextChanged,
                .typingStateChanged:
            true
        case .inputFocusChanged,
                .keyboardFrameChanged:
            isInputFocused
        }
    }
}

enum ChatViewportPerformancePolicy {
    static func shouldMeasureVisibleFrames(
        hasStreamingPreview: Bool,
        isTyping: Bool
    ) -> Bool {
        !hasStreamingPreview && !isTyping
    }
}

enum ChatVoiceOverlayPolicy {
    static func isWalkieTalkieOverlayEnabled(
        isInputFocused: Bool,
        isVoiceRecording: Bool,
        isVoiceFinalizing: Bool,
        isWalkieTalkieRecording: Bool
    ) -> Bool {
        ((!isInputFocused && !isVoiceRecording && !isVoiceFinalizing) || isWalkieTalkieRecording)
    }

    static func allowsDirectSpeakTap(
        isInputFocused: Bool,
        isVoiceRecording: Bool,
        isVoiceFinalizing: Bool,
        isWalkieTalkieRecording: Bool
    ) -> Bool {
        !isVoiceRecording && !isVoiceFinalizing && !isWalkieTalkieRecording
    }

    static let shouldDismissKeyboardBeforeRecording = false
}
