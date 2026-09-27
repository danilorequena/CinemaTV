#if DEBUG && os(iOS)
import SwiftUI

// In-memory fixtures for the approved visual direction. No app persistence.
enum CollectorItemKind: String, CaseIterable, Identifiable {
    case movie = "Filme", series = "Série", season = "Temporada", episode = "Episódio"
    case trailer = "Trailer", music = "Música", note = "Impressão"
    var id: Self { self }
    var symbol: String {
        switch self {
        case .movie: "film"
        case .series: "tv"
        case .season: "rectangle.stack"
        case .episode: "play.tv"
        case .trailer: "play.rectangle"
        case .music: "music.note"
        case .note: "quote.opening"
        }
    }
}

struct CollectorItem: Identifiable {
    var id = UUID()
    var kind: CollectorItemKind
    var title: String
    var subtitle: String
    var artwork: BoxesArtworkKind
    var note: String?
    var author: String?

    func copied() -> Self {
        var copy = self
        copy.id = UUID()
        return copy
    }
}

struct CollectorEdition: Identifiable {
    var id = UUID()
    var title = ""
    var description = ""
    var cover: BoxesArtworkKind = .space
    var author = "Você"
    var inspiredBy: String?
    var entries: [CollectorItem] = []
    var preservedOriginal = false

    var coverTitle: String { title.isEmpty ? "SUA\nEDIÇÃO" : title.uppercased() }
    var byline: String { author == "Você" ? "Sua edição pessoal" : "Uma edição de \(author)" }
    var coverSignature: String { byline.uppercased() }
    var summary: String {
        let works = entries.filter { [.movie, .series, .season, .episode].contains($0.kind) }.count
        let extras = entries.count - works
        return "\(works) \(works == 1 ? "obra" : "obras") · \(extras) \(extras == 1 ? "extra" : "extras")"
    }
    var isReady: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !entries.isEmpty }

    func personalized() -> Self {
        var copy = self
        copy.id = UUID()
        copy.title = "\(title) — meu olhar"
        copy.author = "Você"
        copy.inspiredBy = author
        copy.preservedOriginal = false
        copy.entries = entries.map { $0.copied() }
        return copy
    }

    static let catalog: [CollectorItem] = [
        .init(kind: .movie, title: "Interestelar", subtitle: "2014 · Christopher Nolan", artwork: .space),
        .init(kind: .trailer, title: "O trailer que me ganhou", subtitle: "Interestelar · Trailer oficial", artwork: .space),
        .init(kind: .music, title: "Cornfield Chase", subtitle: "Hans Zimmer · Interestelar", artwork: .space),
        .init(kind: .note, title: "O que ficou comigo", subtitle: "Sobre Interestelar", artwork: .space,
              note: "Talvez o tempo seja só outro jeito de falar sobre quem a gente ama.", author: "Marina"),
        .init(kind: .movie, title: "A Chegada", subtitle: "2016 · Denis Villeneuve", artwork: .arrival),
        .init(kind: .episode, title: "O começo é o fim", subtitle: "Dark · T2 E8", artwork: .dark),
        .init(kind: .series, title: "Dark", subtitle: "Série completa · 3 temporadas", artwork: .dark),
        .init(kind: .season, title: "The Office · Temporada 2", subtitle: "22 episódios", artwork: .office)
    ]
    static let sample = Self(title: "Além do tempo", description: "Histórias que dobram o tempo e ficam com a gente. Minha ordem para assistir, ouvir e sentir de novo.", author: "Marina", entries: Array(catalog.prefix(6)))
    static let personalSample: Self = {
        var edition = sample
        edition.id = UUID()
        edition.author = "Você"
        edition.entries = edition.entries.map {
            var item = $0.copied()
            if item.note != nil { item.author = "Você" }
            return item
        }
        return edition
    }()
    static let shelf: [Self] = [
        personalSample,
        .init(title: "Mundos que ficam", description: "Lugares que continuam comigo depois dos créditos.", cover: .arrival, entries: [catalog[4].copied(), catalog[6].copied()]),
        .init(title: "Só mais um episódio", description: "Meu lugar de conforto no fim do dia.", cover: .office, entries: [catalog[7].copied()])
    ]
}
#endif
