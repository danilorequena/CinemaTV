//
//  VideosView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 09/12/21.
//

import SwiftUI
import WebKit

struct VideosView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: Constants.baseTrailers + videoID) else { return }
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
