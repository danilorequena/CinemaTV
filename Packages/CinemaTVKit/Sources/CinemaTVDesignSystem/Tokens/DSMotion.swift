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
    /// Revelação suave do preenchimento das avaliações por estrela.
    public static let ratingSelection: Animation = .easeOut(duration: 0.42)
    /// Escala final da máscara radial, suficiente para revelar toda a estrela.
    public static let ratingRevealScale: CGFloat = 1.55
    /// Raio do brilho que acompanha o preenchimento.
    public static let ratingGlowRadius: CGFloat = 5
    /// Volta completa aplicada à estrela na direção de um arraste.
    public static let ratingDragRotation = 360.0
    /// Fade usado como alternativa a movimento.
    public static let subtleFade: Animation = .easeOut(duration: 0.16)
    /// Intervalo entre elementos de uma animação em sequência.
    public static let staggerInterval = 0.045
    /// Entrada de conteúdo (stagger de seções).
    public static let entrance: Animation = .spring(duration: 0.6, bounce: 0.18)

    /// Animação respeitando Reduce Motion: retorna nil (sem animação)
    /// quando o usuário pediu menos movimento.
    public static func respecting(_ reduceMotion: Bool, _ animation: Animation = standard) -> Animation? {
        reduceMotion ? nil : animation
    }
}
