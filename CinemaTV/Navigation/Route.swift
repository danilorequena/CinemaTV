//
//  Route.swift
//  CinemaTV
//
//  Rotas de navegação do redesign, incluindo detalhe de série e temporada.
//

import Foundation
import CinemaTVCore

enum Route: Hashable {
    case movieDetail(id: Int)
    case person(id: Int)
    case movieList(category: MovieCategory)
    case discoverDeck

    // V2 — TV Shows
    case tvShowDetail(id: Int)
    /// sourceID: origem da zoom transition quando o push parte de um card
    /// visível (SeasonsCarousel); nil em deep links e menus de contexto.
    case season(tvShowID: Int, seasonNumber: Int, sourceID: String?)
}
