import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

/// Supplied by the deployment configuration, never inferred from a user link.
enum BoxSharingConfiguration {
    static var baseURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "CinemaTVBoxesBaseURL") as? String,
              !value.isEmpty, !value.contains("$("), let url = URL(string: value),
              url.scheme?.lowercased() == "https", url.host != nil else { return nil }
        return url
    }
    static let service = BoxSharingService(baseURL: baseURL)
}

private enum BoxArtworkFormat: String, CaseIterable, Identifiable {
    case story, feed
    var id: Self { self }
    var height: CGFloat { self == .story ? 640 : 450 }
    var title: LocalizedStringKey { self == .story ? "Story · 9:16" : "Feed · 4:5" }
}

struct BoxShareScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let box: BoxDraft
    var sourceEditionID: UUID? = nil
    @State private var name = ""
    @State private var format: BoxArtworkFormat = .story
    @State private var publishedURL: URL?
    @State private var edition: BoxEdition?
    @State private var artwork: [URL: UIImage]?
    @State private var artworkLoad: Task<[URL: Data], Never>?
    @State private var activity: BoxActivity?
    @State private var busy = false
    @State private var error: BoxFailure?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Picker("Share format", selection: $format) {
                        ForEach(BoxArtworkFormat.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    GeometryReader { geometry in
                        let scale = min(0.75, geometry.size.width / 360)
                        BoxShareArtwork(box: displayBox, format: format, images: artwork ?? [:])
                            .frame(width: 360, height: format.height)
                            .scaleEffect(scale, anchor: .topLeading)
                            .frame(width: 360 * scale, height: format.height * scale)
                            .frame(width: geometry.size.width)
                    }
                        .frame(height: format.height * 0.75)
                        .accessibilityLabel("Preview of your shared cover")
                    if sourceEditionID == nil && edition == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your signature").font(.headline)
                            TextField("The name on your box", text: $name).textFieldStyle(.roundedBorder)
                                .textContentType(.nickname).autocorrectionDisabled()
                            Text("A name for your editions. No account needed.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    if BoxSharingConfiguration.baseURL == nil {
                        Label("Links are not available yet. You can still share the cover.", systemImage: "link")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Anyone with the link can open this edition. Changes you make later stay in your box.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button {
                            Task { await share(includeLink: true) }
                        } label: {
                            Label(publishedURL == nil ? String(localized: "Share This Edition") : String(localized: "Share Image and Link"), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(busy || (sourceEditionID == nil && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    }
                    Button("Share Cover Only", systemImage: "photo") { Task { await share(includeLink: false) } }
                        .frame(maxWidth: .infinity).buttonStyle(.bordered).disabled(busy)
                    if busy { ProgressView("Preparing your edition…").frame(maxWidth: .infinity) }
                }.padding(24)
            }
            .background(BoxAppearance.background)
            .navigationTitle("Share Box").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() }.disabled(busy) } }
            .sheet(item: $activity) { payload in ShareSheetView(items: payload.items) { _ in activity = nil } }
            .boxError($error)
            .onAppear { name = box.authorName }
            .task { _ = try? await loadArtwork() }
            .onDisappear {
                artworkLoad?.cancel()
                artworkLoad = nil
            }
        }.preferredColorScheme(.dark).tint(DSColor.accent)
        .interactiveDismissDisabled(busy)
    }

    private var displayBox: BoxDraft {
        if let edition { return edition.box }
        var copy = box
        if sourceEditionID == nil { copy.authorName = name.trimmingCharacters(in: .whitespacesAndNewlines) }
        return copy
    }

    private func loadArtwork() async throws -> [URL: UIImage] {
        try Task.checkCancellation()
        if let artwork { return artwork }
        let load: Task<[URL: Data], Never>
        if let artworkLoad {
            load = artworkLoad
        } else {
            let urls = Set(BoxCoverArtwork.contents(in: box).compactMap { BoxCoverArtwork.url(for: $0) })
            let session = DSImagePipeline.session
            load = Task {
                await withTaskGroup(of: (URL, Data?).self, returning: [URL: Data].self) { group in
                    for url in urls {
                        group.addTask {
                            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
                            guard let (data, response) = try? await session.data(for: request),
                                  (response as? HTTPURLResponse)?.statusCode == 200 else { return (url, nil) }
                            return (url, data)
                        }
                    }
                    var dataByURL: [URL: Data] = [:]
                    for await (url, data) in group {
                        if let data { dataByURL[url] = data }
                    }
                    return dataByURL
                }
            }
            artworkLoad = load
        }
        let dataByURL = await load.value
        try Task.checkCancellation()
        guard !load.isCancelled else { throw CancellationError() }
        let images = dataByURL.compactMapValues { UIImage(data: $0) }
        artwork = images
        artworkLoad = nil
        return images
    }

    private func share(includeLink: Bool) async {
        busy = true
        defer { busy = false }
        do {
            // Freeze the same content artwork for the preview and the rendered image.
            // Missing images keep their content card instead of preventing sharing.
            let images = try await loadArtwork()
            if sourceEditionID == nil, edition == nil, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let store = BoxStore(context: context)
                try store.saveDisplayName(name)
                var signed = displayBox
                for index in signed.contents.indices where signed.contents[index].authorID == signed.authorID && signed.contents[index].authorName?.isEmpty != false {
                    signed.contents[index].authorName = signed.authorName
                }
                let record = try store.save(signed)
                if includeLink { edition = try store.makeEdition(from: record) }
            }
            if includeLink, publishedURL == nil {
                if let sourceEditionID {
                    guard let baseURL = BoxSharingConfiguration.baseURL else { throw BoxShareUIError.links }
                    publishedURL = try BoxShareLink.url(for: sourceEditionID, baseURL: baseURL)
                } else {
                    if let edition { publishedURL = try await BoxSharingConfiguration.service.publish(edition) }
                }
            }
            let rendered = BoxShareArtwork(box: displayBox, format: format, images: images)
                .frame(width: 360, height: format.height)
                .environment(\.colorScheme, .dark).environment(\.dynamicTypeSize, .medium)
            let renderer = ImageRenderer(content: rendered)
            renderer.scale = 3
            guard let image = renderer.uiImage else { throw BoxShareUIError.artwork }
            var items: [Any] = [image]
            if includeLink, let publishedURL { items.append(publishedURL) }
            activity = BoxActivity(items: items)
        } catch is CancellationError {
            // Closing the screen cancels its pending artwork without presenting an error.
        } catch { self.error = BoxFailure(error) }
    }
}

private struct BoxActivity: Identifiable {
    let id = UUID()
    let items: [Any]
}

private enum BoxShareUIError: LocalizedError {
    case artwork, links
    var errorDescription: String? {
        switch self {
        case .artwork: String(localized: "The cover could not be prepared. Please try again.")
        case .links: String(localized: "Links are not available yet.")
        }
    }
}

private struct BoxShareArtwork: View {
    let box: BoxDraft
    let format: BoxArtworkFormat
    let images: [URL: UIImage]
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.18, green: 0.22, blue: 0.25), BoxAppearance.background, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: format == .story ? 24 : 14) {
                Text("CINEMATV BOXES").font(.system(size: 10, weight: .semibold)).tracking(3).foregroundStyle(DSColor.accent)
                Spacer(minLength: 0)
                BoxCoverView(box: box, loadedArtwork: images.mapValues { Image(uiImage: $0) })
                    .frame(width: format == .story ? 220 : 178, height: format == .story ? 304 : 245)
                    .shadow(color: .black.opacity(0.7), radius: 15, x: 12, y: 15)
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Text(box.title).font(.system(size: 23, weight: .bold, design: .serif)).lineLimit(2).minimumScaleFactor(0.6)
                    if !box.authorName.isEmpty { Text(box.authorName).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8)).lineLimit(1) }
                    if let name = box.inspiredByName { Text("Inspired by \(name)").font(.system(size: 11)).lineLimit(1) }
                    Text("\(box.contents.count) items · one personal edition").font(.system(size: 11)).foregroundStyle(.white.opacity(0.65))
                }
                Text("A BOX TO KEEP").font(.system(size: 8, weight: .semibold)).tracking(2).foregroundStyle(.white.opacity(0.5))
            }.padding(format == .story ? 34 : 24)
        }.foregroundStyle(.white).clipped()
    }
}

#if DEBUG
#Preview("Boxes · Compartilhar edição") {
    BoxShareScreen(box: BoxCanvasData.draft)
        .modelContainer(BoxCanvasData.container())
}

#endif
