//
//  CinemaTVCore.swift
//  CinemaTVKit
//
//  Camada de domínio compartilhada entre app, widget e futuros targets
//  (macOS/visionOS): TMDBClient, models, SwiftData e WatchlistStore.
//

import Foundation

// Nomeado *Info para não sombrear o nome do módulo (CinemaTVCore.Tipo
// precisa resolver para o módulo em código cliente).
public enum CinemaTVCoreInfo {
    public static let version = "1.0.0"
}
