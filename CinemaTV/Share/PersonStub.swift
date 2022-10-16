//
//  PersonStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 13/10/22.
//

import Foundation

extension Person {
    static func mock() -> Person {
        return Person(
            adult: false,
            alsoKnownAs: ["Breds Pits", "William Bradley Brad Pitt"],
            biography: "William Bradley Pitt mais conhecido como Brad Pitt (Shawnee, 18 de Dezembro de 1963), é um ator, produtor cinematográfico e empresário norte-americano, fundador e atualmente único dono da produtora de filmes Plan B Entertainment e viticultor e dono da vinícola Miraval.",
            birthday: "1963-12-18",
            deathday: nil,
            gender: 2,
            homepage: nil,
            id: 287,
            imdbID: "nm0000093",
            knownForDepartment: "Acting",
            name: "Brad Pitt",
            placeOfBirth: "Shawnee, Oklahoma, USA",
            popularity: 64.475,
            profilePath: "/ajNaPmXVVMJFg9GWmu6MJzTaXdV.jpg"
        )
    }
}
