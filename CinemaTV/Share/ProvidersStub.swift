//
//  ProvidersStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 10/01/23.
//

import Foundation

extension WatchProvider {
    static func mockArray() -> [WatchProvider] {
        [
            WatchProvider(
                logoPath: "/xbhHHa1YgtpwhC8lb1NQ3ACVcLd.jpg",
                id: 1,
                providerName: "Paramount+",
                displayPriority: 1
            ),
            WatchProvider(
                logoPath: "/x36C6aseF5l4uX99Kpse9dbPwBo.jpg",
                id: 1,
                providerName: "StarZ+",
                displayPriority: 2
            )
        ]
    }
}
