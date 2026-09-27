import SwiftUI
import WebKit

/// Embed exclusivo do Discover. O restante do app mantém seu player em sheet.
struct InlineYouTubePlayer: UIViewRepresentable {
    let videoKey: String
    let isActive: Bool
    let onReady: () -> Void
    let onFailure: () -> Void

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: InlineYouTubePlayer
        var loadedKey: String?
        var active = true
        var disposed = false

        init(parent: InlineYouTubePlayer) { self.parent = parent }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard !disposed, message.frameInfo.isMainFrame,
                  let event = message.body as? String else { return }
            switch event {
            case "ready": parent.onReady()
            case "error": parent.onFailure()
            default: break
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if !disposed { parent.onFailure() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !disposed { parent.onFailure() }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            if !disposed { parent.onFailure() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        configuration.userContentController.add(context.coordinator, name: "trailer")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.loadedKey != videoKey {
            context.coordinator.loadedKey = videoKey
            context.coordinator.active = isActive
            webView.loadHTMLString(html, baseURL: URL(string: "https://cinematv.app"))
        } else if context.coordinator.active != isActive {
            context.coordinator.active = isActive
            webView.evaluateJavaScript("window.cinemaActive = \(isActive ? "true" : "false"); if (!window.cinemaActive && window.player && player.pauseVideo) player.pauseVideo();", completionHandler: nil)
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.disposed = true
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "trailer")
        webView.navigationDelegate = nil
        webView.stopLoading()
        // Remove o iframe e seu áudio mesmo durante uma transição de saída.
        webView.loadHTMLString("", baseURL: nil)
    }

    private var html: String {
        // Só caracteres válidos de IDs YouTube chegam ao HTML/JavaScript.
        let safeKey = videoKey.filter { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
        return """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>html,body{margin:0;background:#000;width:100%;height:100%;overflow:hidden}#player{position:absolute;inset:0;width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe id="player" src="https://www.youtube-nocookie.com/embed/\(safeKey)?enablejsapi=1&playsinline=1&rel=0&origin=https%3A%2F%2Fcinematv.app"
          allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        <script>
        window.cinemaActive = \(isActive ? "true" : "false");
        function notify(event) { window.webkit.messageHandlers.trailer.postMessage(event); }
        function onYouTubeIframeAPIReady() {
          window.player = new YT.Player('player', {events: {
            onReady: function(event) {
              notify('ready');
              if (window.cinemaActive) event.target.playVideo();
            },
            onError: function() { notify('error'); },
            onAutoplayBlocked: function() { notify('ready'); },
            onStateChange: function(event) {
              if (!window.cinemaActive && event.data === 1) event.target.pauseVideo();
            }
          }});
        }
        </script>
        <script src="https://www.youtube.com/iframe_api" onerror="notify('error')"></script>
        </body></html>
        """
    }
}
