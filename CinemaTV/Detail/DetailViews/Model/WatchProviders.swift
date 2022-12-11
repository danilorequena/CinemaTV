//
//  WatchProviders.swift
//  CinemaTV
//
//  Created by Danilo Requena on 11/12/22.
//

import Foundation

// MARK: - WatchProviders
struct WatchProviders: Codable {
    var id: Int?
    var results: ProvidersResults?
}

// MARK: - Results
struct ProvidersResults: Codable {
    var br: ProvidersData?
//    var ae, ar, at, au: ProvidersData?
//    var be, bg, bo, br: ProvidersData?
//    var ca, ch, cl, co: ProvidersData?
//    var cr, cv, cz, de: ProvidersData?
//    var dk, ec, ee, eg: ProvidersData?
//    var es, fi, fr, gb: ProvidersData?
//    var gh, gr, gt, hk: ProvidersData?
//    var hn, hr, hu, id: ProvidersData?
//    var ie, resultsIS, it: ProvidersData?
//    var lt, lv, mu, mx: ProvidersData?
//    var my, mz, nl, no: ProvidersData?
//    var nz, pe, ph, pl: ProvidersData?
//    var pt, py, sa, se: ProvidersData?
//    var sg, si, sk, th: ProvidersData?
//    var tr, tw, tz, ug: ProvidersData?
//    var us, ve, za: ProvidersData?

    enum CodingKeys: String, CodingKey {
//        case ae = "AE"
//        case ar = "AR"
//        case at = "AT"
//        case au = "AU"
//        case be = "BE"
//        case bg = "BG"
//        case bo = "BO"
        case br = "BR"
//        case ca = "CA"
//        case ch = "CH"
//        case cl = "CL"
//        case co = "CO"
//        case cr = "CR"
//        case cv = "CV"
//        case cz = "CZ"
//        case de = "DE"
//        case dk = "DK"
//        case ec = "EC"
//        case ee = "EE"
//        case eg = "EG"
//        case es = "ES"
//        case fi = "FI"
//        case fr = "FR"
//        case gb = "GB"
//        case gh = "GH"
//        case gr = "GR"
//        case gt = "GT"
//        case hk = "HK"
//        case hn = "HN"
//        case hr = "HR"
//        case hu = "HU"
//        case id = "ID"
//        case ie = "IE"
//        case resultsIS = "IS"
//        case it = "IT"
//        case lt = "LT"
//        case lv = "LV"
//        case mu = "MU"
//        case mx = "MX"
//        case my = "MY"
//        case mz = "MZ"
//        case nl = "NL"
//        case no = "NO"
//        case nz = "NZ"
//        case pe = "PE"
//        case ph = "PH"
//        case pl = "PL"
//        case pt = "PT"
//        case py = "PY"
//        case sa = "SA"
//        case se = "SE"
//        case sg = "SG"
//        case si = "SI"
//        case sk = "SK"
//        case th = "TH"
//        case tr = "TR"
//        case tw = "TW"
//        case tz = "TZ"
//        case ug = "UG"
//        case us = "US"
//        case ve = "VE"
//        case za = "ZA"
    }
}

// MARK: - AE
struct ProvidersData: Codable {
    var link: String?
    var rent, buy, flatrate: [WatchProvider]?
}

// MARK: - Buy
struct WatchProvider: Codable, Identifiable {
    var id: ObjectIdentifier?
    
    var logoPath: String?
    var providerID: Int?
    var providerName: String?
    var displayPriority: Int?

    enum CodingKeys: String, CodingKey {
        case logoPath = "logo_path"
        case providerID = "provider_id"
        case providerName = "provider_name"
        case displayPriority = "display_priority"
    }
}


//struct WatchProviders: Codable {
//    let id: Int
//    let results: [WatchProvidersResults]
//}
//
//struct WatchProvidersResults: Codable {
//    var br: [ProviderData]?
//
//    enum CodingKeys: String, CodingKey {
//        case br = "BR"
//    }
//}
//
//struct ProviderData: Codable {
//    let link: String
//    var rent, buy, flatrate: [Providers]?
//}
//
//struct Providers: Codable, Identifiable {
//    var logoPath: String?
//    var id: Int?
//    var providerName: String?
//    var displayPriority: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case logoPath = "logo_path"
//        case id = "provider_id"
//        case providerName = "provider_name"
//        case displayPriority = "display_priority"
//    }
//
//}
