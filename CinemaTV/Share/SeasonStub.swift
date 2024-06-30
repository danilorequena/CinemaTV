//
//  SeasonStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 30/10/22.
//

import Foundation

extension Season {
    static func mock() -> Season {
        Season(
            airDate: "2010-12-05",
            episodeCount: 64,
            id: 3624,
            name: "Season1",
            overview: "overview",
            posterPath: "/zwaj4egrhnXOBIit1tyb4Sbt3KP.jpg",
            seasonNumber: 1
//            episodes: [
//                Episodes(
//                    id: 2,
//                    episodeNumber: 2,
//                    name: "episode test",
//                    overview: "Overview",
//                    runtime: 123,
//                    airDate: ""
//                )
//            ]
        )
    }
    
    static func mockArray() -> [Season] {
        [
            Season(
                airDate: "2010-12-05",
                episodeCount: 64,
                id: 3624,
                name: "Season1",
                overview: "overview",
                posterPath: "/zwaj4egrhnXOBIit1tyb4Sbt3KP.jpg",
                seasonNumber: 1
//                episodes: [
//                    Episodes(
//                        id: 2,
//                        episodeNumber: 2,
//                        name: "episode test",
//                        overview: "Overview",
//                        runtime: 123,
//                        airDate: ""
//                    )
//                ]
            ),
            Season(
                airDate: "2010-12-05",
                episodeCount: 64,
                id: 3624,
                name: "Season1",
                overview: "overview",
                posterPath: "/zwaj4egrhnXOBIit1tyb4Sbt3KP.jpg",
                seasonNumber: 1
//                episodes: [
//                    Episodes(
//                        id: 2,
//                        episodeNumber: 2,
//                        name: "episode test",
//                        overview: "Overview",
//                        runtime: 123,
//                        airDate: ""
//                    )
//                ]
            ),
            Season(
                airDate: "2010-12-05",
                episodeCount: 64,
                id: 3624,
                name: "Season1",
                overview: "overview",
                posterPath: "/zwaj4egrhnXOBIit1tyb4Sbt3KP.jpg",
                seasonNumber: 1
//                episodes: [
//                    Episodes(
//                        id: 2,
//                        episodeNumber: 2,
//                        name: "episode test",
//                        overview: "Overview",
//                        runtime: 123,
//                        airDate: ""
//                    )
//                ]
            )
        ]
    }
}
