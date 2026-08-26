//
//  ShareSheetView.swift
//  CinemaTV
//
//  Bridge do UIActivityViewController para SwiftUI, isolado em Platform/.
//  Usado como fallback do pedido de feature quando não há conta no app
//  Mail — ShareLink não aceita coleção mista de texto + imagens.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onFinish(completed)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
