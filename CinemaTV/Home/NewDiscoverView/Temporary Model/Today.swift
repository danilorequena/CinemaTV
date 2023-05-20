//
//  Today.swift
//  CinemaTV
//
//  Created by Danilo Requena on 06/05/23.
//

import SwiftUI

struct Today: Identifiable {
    var id = UUID().uuidString
    var appName: String
    var appDescription: String
    var appLogo: String
    var bannerTitle: String
    var platformTitle: String
    var artwork: String
}

var todayItems: [Today] = [
    Today(
        appName: "Name",
        appDescription: "Batle Batle Batle Batle Batle",
        appLogo: "LOGO1",
        bannerTitle: "Samash Samash Samash Samash Samash ",
        platformTitle: "Apple Arcade",
        artwork: "LOGO1"
    ),
    Today(
        appName: "Name",
        appDescription: "Batle Batle Batle Batle Batle",
        appLogo: "LOGO1",
        bannerTitle: "Samash Samash Samash Samash Samash ",
        platformTitle: "Apple Arcade",
        artwork: "LOGO1"
    )
]

var dummyText = "Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text Dummy Text."
