//
//  MotionTiltManager.swift
//  CinemaTV
//
//  Tilt do device (Core Motion) alimentando efeitos de profundidade e o
//  shader holográfico da watchlist. Roll/pitch suavizados e limitados a
//  30Hz; respeitar Reduce Motion é responsabilidade de quem consome
//  (não iniciar o manager).
//

import Foundation
import CoreMotion

@MainActor
@Observable
final class MotionTiltManager {
    private let manager = CMMotionManager()

    /// Roll (-π...π) suavizado, relativo à atitude inicial.
    private(set) var roll: Double = 0
    /// Pitch (-π/2...π/2) suavizado, relativo à atitude inicial.
    private(set) var pitch: Double = 0

    private var referenceRoll: Double?
    private var referencePitch: Double?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated {
                self?.ingest(motion)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        referenceRoll = nil
        referencePitch = nil
        roll = 0
        pitch = 0
    }

    private func ingest(_ motion: CMDeviceMotion) {
        // Primeira leitura vira o "zero": o efeito responde ao movimento
        // relativo, não à postura absoluta de segurar o iPhone.
        let refRoll = referenceRoll ?? motion.attitude.roll
        let refPitch = referencePitch ?? motion.attitude.pitch
        if referenceRoll == nil {
            referenceRoll = refRoll
            referencePitch = refPitch
        }

        // Low-pass para suavidade; clamp para o efeito nunca exagerar.
        let alpha = 0.15
        let targetRoll = max(-0.6, min(0.6, motion.attitude.roll - refRoll))
        let targetPitch = max(-0.6, min(0.6, motion.attitude.pitch - refPitch))
        roll += (targetRoll - roll) * alpha
        pitch += (targetPitch - pitch) * alpha
    }
}
