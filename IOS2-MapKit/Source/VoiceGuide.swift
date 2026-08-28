//
//  VoiceGuide.swift
//  IOS2-MapKit
//
//  Wraps AVSpeechSynthesizer so the rest of the app can just call
//  `voiceGuide.speak("Turn right in 200 meters")` without knowing about
//  AVSpeechUtterance configuration.
//
//  THEORY: this is the same pattern as RouteService.swift — wrap an Apple
//  framework in a small, single-purpose class so the ViewController
//  doesn't need to know how AVFoundation works, only that it can "speak"
//  a string. If we ever swap the voice engine, only this file changes.
//

import AVFoundation

final class VoiceGuide {

    private let synthesizer = AVSpeechSynthesizer()

    /// Speaks a single instruction out loud. If something is already being
    /// spoken, it's cancelled first (`.immediate`) so instructions never
    /// overlap or queue up out of order — e.g. an old "turn left" finishing
    /// after a newer "turn right" has already been triggered.
    func speak(_ text: String) {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
