//
//  MovieModels.swift
//  CinemaTVKit
//
//  Mesmos nomes de classe e propriedades dos modelos legados do app —
//  os record types do CloudKit derivam do nome da classe, então a
//  continuidade do sync depende disso. Tudo opcional (regra do CloudKit;
//  nada de @Attribute(.unique)).
//

import Foundation
import SwiftData

@Model
public final class MoviesToWatch {
    public var id: Int64?
    public var counter: Double?
    public var name: String?
    public var overview: String?
    public var profilePath: String?
    /// Ordenação manual (drag-to-reorder). Opcional para manter CloudKit feliz;
    /// itens legados sem valor caem no fim da lista.
    public var sortIndex: Int?
    /// Quando entrou na fila; itens legados ficam nil (fim das ordenações
    /// por recência).
    public var dateAdded: Date?
    /// Data de estreia (ISO yyyy-MM-dd) — alimenta a agenda "Up Next" de
    /// estreias; itens legados ficam nil até o backfill via detalhe.
    public var releaseDate: String?

    public init(
        id: Int64? = nil,
        counter: Double? = nil,
        name: String? = nil,
        overview: String? = nil,
        profilePath: String? = nil,
        sortIndex: Int? = nil,
        dateAdded: Date? = nil,
        releaseDate: String? = nil
    ) {
        self.id = id
        self.counter = counter
        self.name = name
        self.overview = overview
        self.profilePath = profilePath
        self.sortIndex = sortIndex
        self.dateAdded = dateAdded
        self.releaseDate = releaseDate
    }
}

@Model
public final class MoviesWatched {
    public var counter: Double?
    public var id: Int64?
    public var name: String?
    public var overview: String?
    public var profilePath: String?
    /// Quando foi marcado como assistido; itens legados ficam nil (fim das
    /// ordenações por recência).
    public var watchedAt: Date?

    public init(
        counter: Double? = nil,
        id: Int64? = nil,
        name: String? = nil,
        overview: String? = nil,
        profilePath: String? = nil,
        watchedAt: Date? = nil
    ) {
        self.counter = counter
        self.id = id
        self.name = name
        self.overview = overview
        self.profilePath = profilePath
        self.watchedAt = watchedAt
    }
}

public extension MoviesToWatch {
    convenience init(item: MediaItem, sortIndex: Int? = nil) {
        self.init(
            id: Int64(item.id),
            counter: item.voteAverage,
            name: item.title,
            overview: item.overview,
            profilePath: item.posterPath,
            sortIndex: sortIndex
        )
    }
}

public extension MoviesWatched {
    convenience init(item: MediaItem) {
        self.init(
            counter: item.voteAverage,
            id: Int64(item.id),
            name: item.title,
            overview: item.overview,
            profilePath: item.posterPath
        )
    }
}
