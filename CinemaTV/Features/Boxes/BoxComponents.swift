import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

enum BoxAppearance {
    static let background = Color(red: 0.055, green: 0.061, blue: 0.067)
    static let surface = Color(white: 0.105)
}

extension BoxContentKind {
    var boxTitle: LocalizedStringKey {
        switch self {
        case .movie: "Movie"
        case .series: "Series"
        case .season: "Season"
        case .episode: "Episode"
        case .trailer: "Trailer"
        case .soundtrack: "Soundtrack"
        case .review: "Impression"
        }
    }
    var boxSymbol: String {
        switch self {
        case .movie: "film"
        case .series: "tv"
        case .season: "rectangle.stack"
        case .episode: "play.rectangle"
        case .trailer: "play.rectangle.fill"
        case .soundtrack: "music.note"
        case .review: "quote.opening"
        }
    }
}

struct BoxContentRow: View {
    let content: BoxContent
    var number: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.06))
                if let path = content.posterPath, path.hasPrefix("/") {
                    PosterImage(path: path, kind: .thumbnail, fillsContainer: true)
                } else {
                    Image(systemName: content.kind.boxSymbol).foregroundStyle(DSColor.accent)
                }
            }
            .frame(width: 44, height: 58).clipShape(.rect(cornerRadius: 6))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(content.kind.boxTitle).font(.caption).foregroundStyle(DSColor.accent)
                    Spacer()
                    if let number { Text(number, format: .number).font(.caption.monospaced()).foregroundStyle(.tertiary) }
                }
                Text(content.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if !content.subtitle.isEmpty { Text(content.subtitle).font(.caption).foregroundStyle(.secondary) }
                if content.kind == .review {
                    if let text = content.text { Text(text).font(.subheadline).foregroundStyle(.secondary) }
                    HStack {
                        if let name = content.authorName, !name.isEmpty {
                            Text(name).font(.caption.weight(.medium))
                        }
                        if let rating = content.rating {
                            Label(rating.formatted(.number.precision(.fractionLength(0...1))) + "/5", systemImage: "star.fill")
                                .font(.caption).foregroundStyle(DSColor.accent)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(BoxAppearance.surface, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

struct BoxFailure: Identifiable {
    let id = UUID()
    let message: String
    init(_ error: Error) { message = error.localizedDescription }
    init(message: String) { self.message = message }
}

extension View {
    func boxError(_ error: Binding<BoxFailure?>) -> some View {
        alert("Unable to Complete", isPresented: Binding(get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } })) {
            Button("OK", role: .cancel) { error.wrappedValue = nil }
        } message: { Text(error.wrappedValue?.message ?? "") }
    }
}

#if DEBUG
import SwiftData

/// Isolated Canvas data. Never loaded into the application's store.
@MainActor
enum BoxCanvasData {
    static var draft: BoxDraft {
        BoxDraft(
            id: UUID(uuidString: "5C085737-B280-4B09-9BBF-9414C608C045")!,
            title: "Além do tempo",
            description: "Histórias que ficaram comigo, muito depois dos créditos.",
            authorID: "canvas-author", authorName: "Marina",
            contents: [
                // Public TMDB poster, shared by the film and its trailer.
                BoxContent(kind: .movie, title: "Interestelar", subtitle: "2014 · Christopher Nolan", mediaID: 157336, posterPath: "/1pnigkWWy8W032o9TKDneBa3eVK.jpg"),
                BoxContent(kind: .trailer, title: "O trailer que me ganhou", subtitle: "Interestelar", posterPath: "/1pnigkWWy8W032o9TKDneBa3eVK.jpg"),
                BoxContent(kind: .soundtrack, title: "Cornfield Chase", subtitle: "Hans Zimmer"),
                BoxContent(kind: .review, title: "O que ficou comigo", text: "O tempo passa. O que a gente sente encontra um jeito de ficar.", rating: 5, authorID: "canvas-author", authorName: "Marina"),
                BoxContent(kind: .episode, title: "O começo é o fim", subtitle: "Dark · T2 E8", seriesID: 70523, seasonNumber: 2, episodeNumber: 8)
            ])
    }
    static func container() -> ModelContainer {
        let container = try! ModelContainerFactory.makeInMemory()
        try! BoxStore(container: container).save(draft)
        return container
    }
}

struct BoxCanvasNavigation<Content: View>: View {
    @State private var router = AppRouter()
    @Namespace private var zoomNamespace
    private let container = BoxCanvasData.container()
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack(path: $router.trackingPath) {
            content().withMediaDestinations(zoomNamespace: zoomNamespace)
        }
        .modelContainer(container)
        .environment(router)
        .tint(DSColor.accent)
    }
}

#Preview("Boxes · Cards empilhados") {
    @Previewable @State var box = BoxCanvasData.draft

    ScrollView {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Além do tempo").font(.largeTitle.bold())
                Text("A capa nasce do que você guarda.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            BoxCoverView(box: box).frame(width: 260, height: 355)
            Button("Trocar o card da frente", systemImage: "arrow.triangle.2.circlepath") {
                let first = box.contents.removeFirst()
                box.contents.append(first)
            }
            .buttonStyle(.bordered).tint(DSColor.accent)
            HStack(alignment: .top, spacing: 40) {
                VStack(spacing: 10) {
                    BoxCoverView(box: BoxDraft(contents: [BoxCanvasData.draft.contents[3]]))
                        .frame(width: 105, height: 145)
                    Text("Só uma impressão").font(.caption)
                }
                VStack(spacing: 10) {
                    BoxCoverView(box: BoxDraft()).frame(width: 105, height: 145)
                    Text("Pronto para começar").font(.caption)
                }
            }
        }.padding(24).frame(maxWidth: .infinity)
    }
    .background(BoxAppearance.background)
    .preferredColorScheme(.dark)
    .dsImagePipeline()
}
#endif
