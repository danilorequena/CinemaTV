//
//  SeasonModelStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import Foundation

extension SeasonModel {
    static func stubbedSeason() -> SeasonModel {
        SeasonModel(
            id: "60735",
            airDate: "",
            episodes: [
                Episode(
                    airDate: "",
                    episodeNumber: 1,
                    id: 1234,
                    name: "Name",
                    overview: "Name Name Name Name Name Name Name Name ",
                    productionCode: "",
                    runtime: 1234,
                    seasonNumber: 1,
                    showID: 1234,
                    stillPath: "",
                    voteAverage: 1.2,
                    voteCount: 12
//                    crew: [
//                        CrewModel(
//                            job: "",
//                            department: "",
//                            creditID: "1234",
//                            adult: false,
//                            gender: 2,
//                            id: 12345,
//                            knownForDepartment: "",
//                            name: "NAme",
//                            originalName: "Original Name",
//                            popularity: 12,
//                            profilePath: "/obyikiv6rf8hgwUKJKRJdMT3YEK.jpg",
//                            character: "Name",
//                            order: 1
//                        )
//                    ],
//                    guestStars: [
//                        CrewModel(
//                            job: "",
//                            department: "",
//                            creditID: "1234",
//                            adult: false,
//                            gender: 2,
//                            id: 12345,
//                            knownForDepartment: "",
//                            name: "NAme",
//                            originalName: "Original Name",
//                            popularity: 12,
//                            profilePath: "/obyikiv6rf8hgwUKJKRJdMT3YEK.jpg",
//                            character: "Name",
//                            order: 1
//                        )
//                    ]
                )
            ],
            name: "Name",
            overview: "Name Name Name Name Name Name Name Name ",
            seasonModelID: 123,
            posterPath: "/obyikiv6rf8hgwUKJKRJdMT3YEK.jpg",
            seasonNumber: 1
        )
    }
}
