//
//  DSEnvironment.swift
//  CinemaTVKit
//
//  Namespace da zoom transition (card → detail) propagado por environment,
//  para que MediaCard aplique matchedTransitionSource sem acoplar o design
//  system à navegação do app.
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var mediaZoomNamespace: Namespace.ID?
    /// Tilt do device (valores puros; o app alimenta via Core Motion).
    @Entry var dsTilt: DSTiltValue = .zero
    /// Fábrica do shader holográfico (vive no bundle do app; nil em
    /// previews do package — os componentes degradam sem o efeito).
    @Entry var dsHoloShader: DSHoloShaderProvider? = nil
}

/// Roll/pitch relativos e suavizados, sem dependência de CoreMotion —
/// o package continua compilando para plataformas sem giroscópio.
/// nonisolated: tipos de valor construídos fora do MainActor (globals do app).
public nonisolated struct DSTiltValue: Equatable, Sendable {
    public var roll: Double
    public var pitch: Double

    public init(roll: Double, pitch: Double) {
        self.roll = roll
        self.pitch = pitch
    }

    public static let zero = DSTiltValue(roll: 0, pitch: 0)
}

/// Wrapper Equatable estável para a closure do shader — evita invalidar
/// dependentes a cada update de environment (closures não são comparáveis).
public nonisolated struct DSHoloShaderProvider: Equatable, Sendable {
    public let id: String
    public let make: @Sendable (_ angle: Float, _ size: CGSize) -> Shader

    public init(id: String, make: @escaping @Sendable (_ angle: Float, _ size: CGSize) -> Shader) {
        self.id = id
        self.make = make
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// Aplica o shader holográfico quando o app injetou o provider.
public struct DSHoloEffectModifier: ViewModifier {
    @Environment(\.dsHoloShader) private var provider
    private let angle: Double

    public init(angle: Double) {
        self.angle = angle
    }

    public func body(content: Content) -> some View {
        if let provider {
            content.visualEffect { [angle] content, proxy in
                content.colorEffect(provider.make(Float(angle), proxy.size))
            }
        } else {
            content
        }
    }
}

public extension View {
    func dsHoloEffect(angle: Double) -> some View {
        modifier(DSHoloEffectModifier(angle: angle))
    }
}
