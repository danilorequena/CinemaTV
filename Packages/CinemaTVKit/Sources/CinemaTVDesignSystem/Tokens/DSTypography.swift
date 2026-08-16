//
//  DSTypography.swift
//  CinemaTVKit
//
//  Apenas text styles (Dynamic Type sempre funciona). Nunca tamanhos fixos.
//

import SwiftUI

public extension Font {
    /// Título do destaque hero.
    static let dsHeroTitle: Font = .largeTitle.weight(.bold)
    /// Título de seção (rails, blocos do detail).
    static let dsSectionTitle: Font = .title3.weight(.semibold)
    /// Título de card.
    static let dsCardTitle: Font = .subheadline.weight(.semibold)
    /// Metadados (ano, runtime, contadores).
    static let dsCaption: Font = .caption.weight(.medium)
}
