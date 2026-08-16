//
//  ReviewModels.swift
//  CinemaTVKit
//
//  Review pessoal por filme, chaveado por movieID. Registro separado de
//  MoviesWatched de propósito: unmarkWatched deleta a linha de assistidos,
//  e o review precisa sobreviver a desmarcar/remarcar. Tudo opcional
//  (regra do CloudKit; nada de @Attribute(.unique)) — o nome da classe
//  vira record type, então é definitivo.
//

import Foundation
import SwiftData

@Model
public final class MovieReview {
    public var movieID: Int64?
    /// Nota em meias estrelas: 0.5...5.0.
    public var rating: Double?
    public var reviewText: String?
    /// Denormalizados do filme para o card de compartilhamento funcionar
    /// offline (o review pode existir sem a linha de MoviesWatched).
    public var movieTitle: String?
    public var posterPath: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        movieID: Int64? = nil,
        rating: Double? = nil,
        reviewText: String? = nil,
        movieTitle: String? = nil,
        posterPath: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.movieID = movieID
        self.rating = rating
        self.reviewText = reviewText
        self.movieTitle = movieTitle
        self.posterPath = posterPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
