//
//  VoiceGuide.swift
//  IOS2-MapKit
//
//  Ghidare vocală (text-to-speech) pentru instrucțiunile de navigare.
//
//  Ideea de bază — folosirea AVSpeechSynthesizer / AVSpeechUtterance pentru
//  a converti text în vorbire — pornește de la documentația Apple pentru
//  AVFoundation și de la un tutorial bun pe tema asta, "Language Detection
//  and Text to Speech in SwiftUI Apps" (AppCoda), care explică pe scurt
//  cum se configurează o utterance (voce, viteză, pitch). Partea de
//  integrare cu progresul pe rută (când și ce anume se anunță) e scrisă
//  separat, pentru acest proiect — vezi ViewController.swift.
//
//  DE CE UN FIȘIER SEPARAT?
//  Aceeași logică folosită deja pentru RouteService.swift: izolăm un
//  framework Apple (aici AVFoundation) într-o clasă mică, cu o singură
//  responsabilitate. ViewController-ul nu are nevoie să știe cum se
//  configurează o voce sau o rată de vorbire — apelează pur și simplu
//  `voiceGuide.speak("Virează dreapta")` și atât. Dacă la un moment dat
//  vrem să schimbăm motorul de voce (alt serviciu, altă limbă implicită,
//  alt provider), se modifică doar fișierul acesta.
//

import AVFoundation

final class VoiceGuide {

    // AVSpeechSynthesizer este motorul de sinteză vocală oferit de iOS —
    // primește un "utterance" (o propoziție de rostit, cu setările ei) și
    // îl citește cu voce tare prin difuzorul telefonului.
    private let synthesizer = AVSpeechSynthesizer()

    /// Rostește o singură instrucțiune.
    ///
    /// Dacă sintetizatorul vorbește deja ceva în momentul apelului, îl
    /// oprim imediat (`.immediate`) înainte să pornim noua rostire. Motivul
    /// e simplu: dacă utilizatorul se apropie rapid de două viraje
    /// consecutive, nu vrem ca instrucțiunea veche ("virează stânga") să
    /// se termine de citit peste cea nouă ("virează dreapta") — ar suna
    /// confuz și, mai grav, ar putea induce în eroare exact în momentul
    /// în care precizia contează cel mai mult.
    func speak(_ text: String) {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Vocea se alege automat după limba curentă a dispozitivului
        // (Locale.current), ca instrucțiunile să sune natural indiferent
        // dacă telefonul e setat pe română, engleză sau altă limbă.
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)

        // Rata implicită oferită de sistem — suficient de clară pentru
        // ascultare în mașină, fără să fie nici prea rapidă, nici
        // exagerat de lentă.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
    }
}
