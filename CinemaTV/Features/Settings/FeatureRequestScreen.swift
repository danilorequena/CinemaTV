//
//  FeatureRequestScreen.swift
//  CinemaTV
//
//  Composer de pedido de feature: texto livre + até 3 screenshots,
//  enviado por e-mail para cinematv@nscode.co (curadoria humana).
//  Sem conta no app Mail, cai no share sheet — único fallback que
//  preserva texto e imagens juntos (o destinatário vai na 1ª linha).
//

import SwiftUI
import PhotosUI
import MessageUI
import CinemaTVDesignSystem

struct FeatureRequestScreen: View {
    @Environment(\.dismiss) private var dismiss

    private static let recipient = "cinematv@nscode.co"
    private static let maxImages = 3

    @State private var text = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var attachments: [ImageAttachment] = []
    @State private var showsMailComposer = false
    @State private var showsShareFallback = false
    @State private var showsSendFailedAlert = false

    /// Guarda o PhotosPickerItem de origem para manter picker e
    /// thumbnails em sincronia na remoção, mesmo com loads que falham.
    private struct ImageAttachment: Identifiable {
        let id = UUID()
        let item: PhotosPickerItem
        let image: UIImage
        let jpegData: Data
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                editor
                attachmentsSection
                sendButton
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.md)
            .padding(.bottom, DSSpacing.xxl)
        }
        .navigationTitle("Request a Feature")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedItems) {
            await rebuildAttachments()
        }
        .sheet(isPresented: $showsMailComposer) {
            MailComposeView(
                recipients: [Self.recipient],
                subject: emailSubject,
                body: emailBody,
                attachments: mailAttachments
            ) { result in
                showsMailComposer = false
                switch result {
                case .sent:
                    dismiss()
                case .failed:
                    showsSendFailedAlert = true
                default:
                    // Cancelado/salvo: mantém o rascunho na tela.
                    break
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showsShareFallback) {
            ShareSheetView(items: [shareText] + attachments.map(\.image)) { completed in
                showsShareFallback = false
                if completed { dismiss() }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Couldn't send your request", isPresented: $showsSendFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }

    // MARK: - Subviews

    private var editor: some View {
        TextEditor(text: $text)
            .frame(minHeight: 160)
            .scrollContentBackground(.hidden)
            .padding(DSSpacing.sm)
            .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Describe the feature you'd like to see")
                        .foregroundStyle(.tertiary)
                        .padding(DSSpacing.md)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: Self.maxImages,
                matching: .images
            ) {
                Label("Add Screenshots", systemImage: "photo.badge.plus")
            }

            if !attachments.isEmpty {
                HStack(spacing: DSSpacing.md) {
                    ForEach(attachments) { attachment in
                        thumbnail(for: attachment)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func thumbnail(for attachment: ImageAttachment) -> some View {
        Image(uiImage: attachment.image)
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 72)
            .clipShape(.rect(cornerRadius: DSRadius.card))
            .overlay(alignment: .topTrailing) {
                Button {
                    remove(attachment)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .padding(DSSpacing.xs)
                .accessibilityLabel("Remove screenshot")
            }
    }

    private var sendButton: some View {
        Button {
            send()
        } label: {
            Label("Send Request", systemImage: "paperplane.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Actions

    private func send() {
        if MFMailComposeViewController.canSendMail() {
            showsMailComposer = true
        } else {
            showsShareFallback = true
        }
    }

    private func remove(_ attachment: ImageAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        selectedItems.removeAll { $0 == attachment.item }
    }

    /// Rebuild total a cada mudança de seleção: ≤3 itens, barato e
    /// imune a bugs de diffing. Loads que falham são pulados.
    private func rebuildAttachments() async {
        var rebuilt: [ImageAttachment] = []
        for item in selectedItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            let scaled = downscaled(image, maxDimension: 1600)
            guard let jpeg = scaled.jpegData(compressionQuality: 0.7) else { continue }
            rebuilt.append(ImageAttachment(item: item, image: scaled, jpegData: jpeg))
        }
        attachments = rebuilt
    }

    /// Reduz para caber em e-mail (~300–600KB por JPEG) e normaliza
    /// HEIC/HDR de quebra.
    private func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxDimension else { return image }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - E-mail

    private var mailAttachments: [MailComposeView.Attachment] {
        attachments.enumerated().map { index, attachment in
            MailComposeView.Attachment(
                data: attachment.jpegData,
                mimeType: "image/jpeg",
                fileName: "screenshot-\(index + 1).jpg"
            )
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var emailSubject: String {
        String(localized: "CinemaTV Feature Request — v\(appVersion)")
    }

    private var emailBody: String {
        let footer = String(
            localized: "App: CinemaTV \(appVersion)\niOS: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"
        )
        return text + "\n\n---\n" + footer
    }

    /// Texto do fallback: o share sheet não pré-preenche destinatário,
    /// então ele vai na primeira linha.
    private var shareText: String {
        "To: \(Self.recipient)\n\n" + emailBody
    }
}

#Preview {
    NavigationStack {
        FeatureRequestScreen()
    }
}
