//
//  RoadmapModels.swift
//  CinemaTVCore
//
//  Tipos do roadmap público: changelog (What's New) e backlog (Coming
//  Soon). Conteúdo autoral embarcado em AppRoadmap; créditos guardam o
//  nome de quem sugeriu e são exibidos verbatim (nome não se traduz).
//

import Foundation

/// Categoria de uma sugestão/mudança. Compartilhada pelo changelog,
/// backlog e pelo picker da tela de Request a Feature.
public enum SuggestionKind: String, CaseIterable, Identifiable, Sendable, Hashable, Codable {
    case feature
    case improvement
    case bug

    public var id: String { rawValue }

    /// Símbolo SF da categoria; o tint fica por conta da view.
    public var symbolName: String {
        switch self {
        case .feature: "sparkles"
        case .improvement: "wand.and.stars"
        case .bug: "ladybug"
        }
    }

    public var localizedName: String {
        switch self {
        case .feature: String(localized: "New Feature", bundle: .module)
        case .improvement: String(localized: "Improvement", bundle: .module)
        case .bug: String(localized: "Bug", bundle: .module)
        }
    }

    /// Tag em inglês fixo para o assunto do e-mail: a triagem na caixa
    /// do dev não pode variar com o locale de quem envia.
    public var emailTag: String {
        switch self {
        case .feature: "Feature Request"
        case .improvement: "Improvement"
        case .bug: "Bug Report"
        }
    }

    /// Label aplicada na issue do GitHub criada pelo app ("bug" reusa
    /// a label padrão do repo).
    public var issueLabel: String {
        switch self {
        case .feature: "feature-request"
        case .improvement: "improvement"
        case .bug: "bug"
        }
    }
}

/// Uma mudança dentro de uma release do changelog.
public struct ChangelogEntry: Identifiable, Sendable {
    /// Slug estável, ex.: "region-override".
    public let id: String
    public let kind: SuggestionKind
    public let text: String
    public let credit: String?

    public init(id: String, kind: SuggestionKind, text: String, credit: String? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.credit = credit
    }
}

/// Uma versão publicada do app e suas mudanças.
public struct ChangelogRelease: Identifiable, Sendable {
    public let version: String
    public let date: Date
    public let entries: [ChangelogEntry]

    public var id: String { version }

    public init(version: String, date: Date, entries: [ChangelogEntry]) {
        self.version = version
        self.date = date
        self.entries = entries
    }
}
