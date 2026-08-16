//
//  YouTubePlayerView.swift
//  CinemaTV
//
//  Player de trailer (embed do YouTube via WKWebView). Único ponto de
//  UIKit fora do sistema — isolado em Platform/ para manter o design
//  system e o core livres de UIKit.
//
//  IMPORTANTE: o embed é carregado via loadHTMLString com baseURL de um
//  domínio NEUTRO (origin de "site terceiro"). Duas armadilhas já
//  validadas em simulador: URLRequest direto no /embed chega sem origin
//  e falha; e baseURL do próprio youtube.com também falha (erro 152-4 —
//  o player rejeita embed "hospedado" no próprio YouTube).
//

import SwiftUI
import WebKit
import CinemaTVCore
import CinemaTVDesignSystem

struct YouTubePlayerView: View {
    let video: Video

    var body: some View {
        WebView(videoKey: video.key)
            .background(.black)
            .ignoresSafeArea(edges: .bottom)
            // Válvula de escape: se o embed for bloqueado (anti-bot do
            // YouTube em alguns ambientes), o trailer continua acessível.
            .overlay(alignment: .topTrailing) {
                if let watchURL = URL(string: "https://www.youtube.com/watch?v=\(video.key)") {
                    Link(destination: watchURL) {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: "arrow.up.right")
                            Text("Open in YouTube")
                        }
                        .font(.dsCaption)
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.vertical, DSSpacing.sm)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .padding(DSSpacing.md)
                }
            }
            .environment(\.colorScheme, .dark)
    }
}

#Preview {
    YouTubePlayerView(
        video: Video(
            id: "1",
            key: "dQw4w9WgXcQ",
            name: "Official Trailer",
            site: "YouTube",
            type: "Trailer",
            official: true
        )
    )
}

private struct WebView: UIViewRepresentable {
    let videoKey: String

    final class Coordinator {
        var loadedKey: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        // UA de Safari móvel: sem ele o YouTube trata o WKWebView "cru"
        // como bot ("Sign in to confirm you're not a bot").
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedKey != videoKey else { return }
        context.coordinator.loadedKey = videoKey
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://cinematv.app"))
    }

    private var embedHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body { margin: 0; background: #000; }
            .container { position: fixed; inset: 0; }
            iframe { width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
        <div class="container">
        <iframe
            src="https://www.youtube-nocookie.com/embed/\(videoKey)?playsinline=1&rel=0"
            allow="encrypted-media; picture-in-picture"
            allowfullscreen>
        </iframe>
        </div>
        </body>
        </html>
        """
    }
}
