import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct BoxDetailScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Query private var records: [PersonalBox]
    @State private var editing: BoxDraft?
    @State private var showsShare = false
    @State private var confirmsDelete = false
    @State private var error: BoxFailure?
    private let id: UUID

    init(id: UUID) {
        self.id = id
    }

    private var record: PersonalBox? { records.first { $0.id == id } }

    var body: some View {
        Group {
            if let record, let box = try? BoxStore(context: context).draft(for: record) {
                BoxExperienceView(box: box) {
                    if record.isOriginal == true {
                        Label("Original edition · saved as received", systemImage: "lock.fill")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Create My Version", systemImage: "square.on.square") { adapt(box, source: record.sourceEditionID) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("Edit Box", systemImage: "pencil") { editing = box }.buttonStyle(.bordered)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Share Box", systemImage: "square.and.arrow.up") { showsShare = true }
                        Menu {
                            if record.isOriginal != true { Button("Edit Box", systemImage: "pencil") { editing = box } }
                            Button("Remove Box", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                        } label: { Label("Box Options", systemImage: "ellipsis") }
                    }
                }
                .sheet(isPresented: $showsShare) {
                    BoxShareScreen(box: box, sourceEditionID: record.isOriginal == true ? record.sourceEditionID : nil)
                }
            } else {
                ContentUnavailableView("Box Unavailable", systemImage: "shippingbox", description: Text("This box could not be read. It may have been removed from your library."))
            }
        }
        .background(BoxAppearance.background).preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $editing) { draft in
            BoxComposerScreen(draft: draft) {
                if draft.id != id { router.push(.box(id: draft.id)) }
            }
        }
        .confirmationDialog("Remove this box from your library?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Remove Box", role: .destructive) {
                do {
                    if let record { try BoxStore(context: context).delete(record) }
                    dismiss()
                } catch { self.error = BoxFailure(error) }
            }
        } message: { Text("Links already shared keep their published edition.") }
        .boxError($error)
    }

    private func adapt(_ box: BoxDraft, source: UUID?) {
        do {
            let profile = try BoxStore(context: context).profile()
            editing = BoxStore.inspiredDraft(from: BoxEdition(id: source ?? UUID(), box: box), authorID: profile.id ?? "", authorName: profile.displayName ?? "")
        } catch { self.error = BoxFailure(error) }
    }
}

struct BoxExperienceView<Actions: View>: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let box: BoxDraft
    @ViewBuilder let actions: () -> Actions
    @State private var opened = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BoxCoverView(box: box).frame(width: 210, height: 290)
                    .rotation3DEffect(.degrees(opened ? -8 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.3)
                    .shadow(color: .black.opacity(0.7), radius: 20, x: 10, y: 16)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                VStack(alignment: .leading, spacing: 10) {
                    Text("CINEMATV BOXES").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(DSColor.accent)
                    Text(box.title).font(.system(.largeTitle, design: .serif, weight: .bold))
                    if !box.authorName.isEmpty { Text("An edition by \(box.authorName)").font(.subheadline).foregroundStyle(.secondary) }
                    if let name = box.inspiredByName { Text("Inspired by \(name)").font(.caption).foregroundStyle(DSColor.accent) }
                    if !box.description.isEmpty { Text(box.description).foregroundStyle(.secondary).padding(.top, 4) }
                }
                actions().frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("Inside this Box").font(.title3.bold())
                    Spacer()
                    Text("\(box.contents.count) items").font(.caption).foregroundStyle(.secondary)
                }.padding(.top, 8)
                ForEach(Array(box.contents.enumerated()), id: \.element.id) { index, content in
                    if canOpen(content) {
                        Button { activate(content) } label: { BoxContentRow(content: content, number: index + 1) }
                            .buttonStyle(.plain).accessibilityHint("Open content")
                    } else {
                        BoxContentRow(content: content, number: index + 1)
                    }
                }
            }.padding(24)
        }
        .background(BoxAppearance.background)
        .task {
            if !reduceMotion { withAnimation(.easeOut(duration: 0.6)) { opened = true } }
        }
    }

    private func canOpen(_ content: BoxContent) -> Bool {
        switch content.kind {
        case .movie, .series: content.mediaID != nil
        case .season: content.seriesID != nil && content.seasonNumber != nil
        case .episode: content.seriesID != nil && content.seasonNumber != nil && content.episodeNumber != nil
        case .trailer, .soundtrack: safeURL(content.externalURL) != nil
        case .review: false
        }
    }
    private func activate(_ content: BoxContent) {
        switch content.kind {
        case .movie:
            if let id = content.mediaID { router.push(.movieDetail(id: id)) }
        case .series:
            if let id = content.mediaID { router.push(.tvShowDetail(id: id)) }
        case .season:
            if let id = content.seriesID, let season = content.seasonNumber { router.push(.season(tvShowID: id, seasonNumber: season, sourceID: nil)) }
        case .episode:
            if let id = content.seriesID, let season = content.seasonNumber, let episode = content.episodeNumber {
                router.push(.boxEpisode(tvShowID: id, seasonNumber: season, episodeNumber: episode))
            }
        case .trailer, .soundtrack:
            if let url = safeURL(content.externalURL) { openURL(url) }
        case .review: break
        }
    }
    private func safeURL(_ url: URL?) -> URL? {
        guard let url, url.scheme?.lowercased() == "https", url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }
}

struct BoxEpisodeScreen: View {
    @Environment(\.tmdbClient) private var client
    let tvShowID: Int
    let seasonNumber: Int
    let episodeNumber: Int
    @State private var episodes: [EpisodeSummary]?
    @State private var error: String?
    @State private var attempt = 0

    var body: some View {
        Group {
            if let episodes, episodes.contains(where: { $0.episodeNumber == episodeNumber }) {
                EpisodeDetailScreen(selection: EpisodeSelection(tvShowID: tvShowID, seasonNumber: seasonNumber, episodes: episodes, initialEpisodeNumber: episodeNumber, sourceID: nil))
            } else if let error {
                ContentUnavailableView {
                    Label("Episode Unavailable", systemImage: "tv")
                } description: { Text(error) } actions: { Button("Try Again") { attempt += 1 } }
            } else { ProgressView() }
        }
        .task(id: attempt) {
            error = nil
            do {
                let details: SeasonDetails = try await client.fetch(.tvShowSeason(id: tvShowID, season: seasonNumber))
                guard details.episodes.contains(where: { $0.episodeNumber == episodeNumber }) else {
                    error = String(localized: "This episode is no longer available in the catalog.")
                    return
                }
                episodes = details.episodes
            } catch is CancellationError { } catch { self.error = error.localizedDescription }
        }
    }
}

#if DEBUG
#Preview("Boxes · Edição pessoal") {
    BoxCanvasNavigation {
        BoxDetailScreen(id: BoxCanvasData.draft.id)
    }
}

#endif
