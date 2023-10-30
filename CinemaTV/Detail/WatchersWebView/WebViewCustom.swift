//
//  WebViewCustom.swift
//  CinemaTV
//
//  Created by Danilo Requena on 29/10/23.
//

import SwiftUI
import WebKit

struct WebViewCustom: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
