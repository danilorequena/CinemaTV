//
//  DSColor.swift
//  CinemaTVKit
//
//  Paleta semântica. Texto usa .primary/.secondary do sistema; fundos ficam
//  com o sistema (Liquid Glass depende disso) — aqui vive só o que é da marca.
//

import SwiftUI

public enum DSColor {
    /// Cor de marca — âmbar de letreiro de cinema.
    public static let accent = Color(red: 1.0, green: 0.72, blue: 0.20)

    /// Cor da nota conforme a faixa (0...10), usada pelo RatingGauge e tags.
    public static func rating(for value: Double) -> Color {
        switch value {
        case 7...: .green
        case 5..<7: .orange
        default: .red
        }
    }
}
