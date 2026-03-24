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
