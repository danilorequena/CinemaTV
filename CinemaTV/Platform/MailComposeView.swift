//
//  MailComposeView.swift
//  CinemaTV
//
//  Bridge do MFMailComposeViewController para SwiftUI, isolado em
//  Platform/ como os demais pontos de UIKit. O delegate só reporta o
//  resultado via onFinish — quem apresenta (sheet SwiftUI) decide
//  fechar, então não chamamos dismiss no controller aqui.
//

import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    struct Attachment {
        let data: Data
        let mimeType: String
        let fileName: String
    }

    let recipients: [String]
    let subject: String
    let body: String
    let attachments: [Attachment]
    let onFinish: (MFMailComposeResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            controller.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult) -> Void

        init(onFinish: @escaping (MFMailComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: (any Error)?
        ) {
            onFinish(result)
        }
    }
}
