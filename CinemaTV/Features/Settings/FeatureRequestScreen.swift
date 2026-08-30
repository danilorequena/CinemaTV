//
//  FeatureRequestScreen.swift
//  CinemaTV
//
//  Composer de pedido de feature: categoria + nome opcional (vira o
//  crédito no What's New) + texto livre + até 3 screenshots.
//  Caminho principal: issue no GitHub (fica acompanhável em My
//  Requests); e-mail segue como alternativa — e é o único caminho
//  que carrega screenshots. Sem conta no app Mail, o e-mail cai no
//  share sheet, único fallback que preserva texto e imagens juntos.
//

import SwiftUI
import PhotosUI
import MessageUI
import CinemaTVCore
import CinemaTVDesignSystem

struct FeatureRequestScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.feedbackClient) private var feedbackClient

    private static let recipient = "cinematv@nscode.co"
    private static let maxImages = 3

    @State private var text = ""
    @State private var requesterName = ""
    @State private var category: SuggestionKind = .feature
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var attachments: [ImageAttachment] = []
    @State private var showsMailComposer = false
    @State private var showsShareFallback = false
    @State private var showsSendFailedAlert = false
    @State private var showsIssueFailedAlert = false
    @State private var isSending = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case message
    }

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
                header
                categoryPicker
                nameField
                messageSection
                attachmentsSection
                sendButton
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.md)
            .padding(.bottom, DSSpacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Request a Feature")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
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
        .alert("Couldn't send to GitHub", isPresented: $showsIssueFailedAlert) {
            Button("Try Again") { submit() }
            Button("Send by Email") { sendViaEmail() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Check your connection, or send it by email instead.")
        }
    }

    // MARK: - Subviews

    /// Convite + promessa de crédito: é daqui que sai o "Suggested by"
    /// do What's New.
    private var header: some View {
        VStack(spacing: DSSpacing.sm) {
            Image(systemName: "lightbulb.max")
                .font(.title2)
                .foregroundStyle(DSColor.accent)
                .accessibilityHidden(true)
            Text("Every request is read by a human. If we ship your idea, you'll get credit in What's New.")
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryPicker: some View {
        GlassSegmentedPicker(
            selection: $category,
            segments: SuggestionKind.allCases.map { kind in
                // Text(verbatim:): localizedName já resolveu no catálogo
                // do Core; LocalizedStringKey re-resolveria no do app.
                .init(kind, label: Text(verbatim: kind.localizedName))
            }
        )
    }

    private var nameField: some View {
        TextField("Your name or @handle (optional)", text: $requesterName)
            .textContentType(.name)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .onSubmit { focusedField = .message }
            .focused($focusedField, equals: .name)
            .padding(DSSpacing.md)
            .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
    }

    private var messageSection: some View {
        VStack(alignment: .trailing, spacing: DSSpacing.xs) {
            editor
            characterGuidance
        }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .frame(minHeight: 160)
            .scrollContentBackground(.hidden)
            .padding(DSSpacing.sm)
            .focused($focusedField, equals: .message)
            .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(editorPlaceholder)
                        .foregroundStyle(.tertiary)
                        .padding(DSSpacing.md)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private var editorPlaceholder: LocalizedStringKey {
        switch category {
        case .feature: "Describe the feature you'd like to see"
        case .improvement: "What could work better, and how?"
        case .bug: "Describe what went wrong and where"
        }
    }

    /// Guia, não limite: o disable do envio continua só em texto vazio.
    private var characterGuidance: some View {
        Group {
            if text.isEmpty {
                Text("A sentence or two is plenty.")
            } else {
                Text("\(text.count) characters")
            }
        }
        .font(.dsCaption)
        .foregroundStyle(.secondary)
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

                if feedbackClient.configuration.canCreateIssues {
                    Text("Screenshots are only included when sending by email.")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
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
        VStack(spacing: DSSpacing.sm) {
            Button {
                submit()
            } label: {
                if isSending {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Send Request", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glassProminent)
            .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if feedbackClient.configuration.canCreateIssues {
                Button("Send by Email Instead") {
                    sendViaEmail()
                }
                .font(.footnote)
                .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Actions

    /// GitHub quando há token; senão o e-mail segue sendo o caminho.
    private func submit() {
        if feedbackClient.configuration.canCreateIssues {
            Task { await sendViaGitHub() }
        } else {
            sendViaEmail()
        }
    }

    private func sendViaEmail() {
        if MFMailComposeViewController.canSendMail() {
            showsMailComposer = true
        } else {
            showsShareFallback = true
        }
    }

    private func sendViaGitHub() async {
        focusedField = nil
        isSending = true
        defer { isSending = false }
        do {
            let issue = try await feedbackClient.createIssue(
                title: issueTitle,
                body: issueBody,
                labels: [category.issueLabel]
            )
            let trimmedName = requesterName.trimmingCharacters(in: .whitespacesAndNewlines)
            FeatureRequestLog().append(LoggedFeatureRequest(
                issue: issue,
                kind: category,
                requesterName: trimmedName.isEmpty ? nil : trimmedName,
                createdAt: .now
            ))
            dismiss()
        } catch {
            showsIssueFailedAlert = true
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

    /// Assunto e metadados em inglês fixo: são para a triagem na caixa
    /// do dev, não para quem envia.
    private var emailSubject: String {
        "CinemaTV \(category.emailTag) — v\(appVersion)"
    }

    /// A linha "From:" também é o crédito que o app lê de volta da
    /// issue (FeedbackIssue.credit) — o formato é contrato.
    private var metadataFooter: String {
        let trimmedName = requesterName.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        Category: \(category.emailTag)
        From: \(trimmedName.isEmpty ? "—" : trimmedName)
        App: CinemaTV \(appVersion)
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
    }

    private var emailBody: String {
        text + "\n\n---\n" + metadataFooter
    }

    // MARK: - GitHub

    private var issueTitle: String {
        let firstLine = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        return String(firstLine.prefix(72))
    }

    private var issueBody: String {
        var body = text + "\n\n---\n" + metadataFooter
        if !attachments.isEmpty {
            body += "\nScreenshots selected in app: \(attachments.count) (not uploaded; ask by email)"
        }
        return body
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
