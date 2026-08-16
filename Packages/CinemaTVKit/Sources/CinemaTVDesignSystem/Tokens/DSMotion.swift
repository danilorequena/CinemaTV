//
//  DSMotion.swift
//  CinemaTVKit
//
//  Vocabulário único de animação do app. Todo withAnimation do redesign
//  passa por aqui, o que centraliza o respeito a Reduce Motion.
//

import SwiftUI

public enum DSMotion {
    /// Spring padrão para mudanças de estado de UI.
    public static let standard: Animation = .spring(duration: 0.45, bounce: 0.22)
    /// Spring curto para feedback imediato (botões, toggles).
    public static let snappy: Animation = .snappy(duration: 0.28)
    /// Entrada de conteúdo (stagger de seções).
    public static let entrance: Animation = .spring(duration: 0.6, bounce: 0.18)

    /// Animação respeitando Reduce Motion: retorna nil (sem animação)
    /// quando o usuário pediu menos movimento.
    public static func respecting(_ reduceMotion: Bool, _ animation: Animation = standard) -> Animation? {
        reduceMotion ? nil : animation
    }
}
