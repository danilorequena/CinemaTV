import SwiftUI
import CinemaTVCore

/// The same ordered cards and artwork are used on screen and in image exports.
public enum BoxCoverArtwork {
    public static func contents(in box: BoxDraft) -> [BoxContent] {
        // Keep large boxes inexpensive to draw; the full collection stays in the box.
        Array(box.contents.prefix(5))
    }

    public static func url(for content: BoxContent) -> URL? {
        guard content.kind != .review, let path = content.posterPath, path.hasPrefix("/") else { return nil }
        return TMDBImage.url(path: path, size: .poster)
    }
}

/// A small stack made from the box's own contents, with the first item in front.
public struct BoxCoverView: View {
    private let box: BoxDraft
    /// A supplied map disables asynchronous loading, including for missing images.
    private let loadedArtwork: [URL: Image]?

    public init(box: BoxDraft, loadedArtwork: [URL: Image]? = nil) {
        self.box = box
        self.loadedArtwork = loadedArtwork
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let contents = BoxCoverArtwork.contents(in: box)
            if contents.isEmpty {
                emptyStack(size: size)
            } else {
                ZStack {
                    ForEach(Array(contents.enumerated().reversed()), id: \.element.id) { index, content in
                        let depth = CGFloat(index)
                        BoxContentCoverCard(content: content, loadedArtwork: loadedArtwork)
                            .frame(width: size.width * (contents.count == 1 ? 0.86 : 0.80), height: size.height * (contents.count == 1 ? 0.84 : 0.73))
                            .rotationEffect(.degrees(Double(index) * 2.5 - 3))
                            .shadow(color: .black.opacity(0.38), radius: size.width * 0.035, x: 0, y: size.width * 0.025)
                            .position(x: size.width * (contents.count == 1 ? 0.50 : 0.46 + depth * 0.025), y: size.height * (contents.count == 1 ? 0.51 : 0.60 - depth * 0.057))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Label(box.contents.count.formatted(), systemImage: "square.stack.3d.up")
                        .font(.system(size: size.width * 0.057, weight: .semibold))
                        .padding(.horizontal, size.width * 0.055)
                        .padding(.vertical, size.width * 0.035)
                        .foregroundStyle(Color(white: 0.12))
                        .background(DSColor.accent, in: .capsule)
                        .padding(.trailing, size.width * 0.025)
                        .padding(.bottom, size.height * 0.01)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(box.title.isEmpty ? "CinemaTV Box" : box.title)
        .accessibilityValue(Text("\(box.contents.count) items", bundle: .module))
    }

    private func emptyStack(size: CGSize) -> some View {
        ZStack {
            ForEach((0..<3).reversed(), id: \.self) { index in
                RoundedRectangle(cornerRadius: size.width * 0.045)
                    .fill(Color(white: 0.12 + Double(index) * 0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: size.width * 0.045)
                            .strokeBorder(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: index == 0 ? [4, 4] : []))
                    }
                    .overlay {
                        if index == 0 {
                            Image(systemName: "plus")
                                .font(.system(size: size.width * 0.16, weight: .ultraLight))
                                .foregroundStyle(DSColor.accent)
                        }
                    }
                    .frame(width: size.width * 0.80, height: size.height * 0.73)
                    .rotationEffect(.degrees(Double(index) * 5 - 3))
                    .position(x: size.width * (0.46 + CGFloat(index) * 0.035), y: size.height * (0.57 - CGFloat(index) * 0.06))
            }
        }
    }
}

private struct BoxContentCoverCard: View {
    let content: BoxContent
    let loadedArtwork: [URL: Image]?

    private var isNote: Bool { content.kind == .review }
    private var ink: Color { isNote ? Color(red: 0.23, green: 0.19, blue: 0.13) : .white }
    private var tint: Color {
        switch content.kind {
        case .movie: Color(red: 0.16, green: 0.31, blue: 0.35)
        case .series, .season: Color(red: 0.31, green: 0.23, blue: 0.36)
        case .episode: Color(red: 0.24, green: 0.33, blue: 0.27)
        case .trailer: Color(red: 0.24, green: 0.32, blue: 0.45)
        case .soundtrack: Color(red: 0.49, green: 0.28, blue: 0.20)
        case .review: Color(red: 0.90, green: 0.85, blue: 0.74)
        }
    }
    private var symbol: String {
        switch content.kind {
        case .movie: "film"
        case .series: "tv"
        case .season: "rectangle.stack"
        case .episode: "play.rectangle"
        case .trailer: "play.fill"
        case .soundtrack: "music.note"
        case .review: "quote.opening"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                tint
                if !isNote {
                    artwork(width: width)
                    LinearGradient(colors: [.black.opacity(0.18), .clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                }
                VStack(alignment: .leading, spacing: width * 0.065) {
                    Label(content.title, systemImage: symbol)
                        .font(.system(size: width * 0.062, weight: .semibold))
                        .lineLimit(1)
                        .padding(.horizontal, width * 0.07)
                        .frame(maxWidth: .infinity, minHeight: width * 0.17, alignment: .leading)
                        .background(tint.opacity(isNote ? 1 : 0.94))
                    if isNote {
                        VStack(alignment: .leading, spacing: width * 0.06) {
                            Image(systemName: symbol).font(.system(size: width * 0.18, weight: .bold)).opacity(0.5)
                            Text(content.text ?? content.title)
                                .font(.system(size: width * 0.11, weight: .medium, design: .serif))
                                .lineLimit(6).minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, width * 0.085)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: width * 0.035) {
                        if isNote {
                            if let rating = content.rating {
                                Label(rating.formatted(.number.precision(.fractionLength(0...1))) + "/5", systemImage: "star.fill")
                                    .font(.system(size: width * 0.075, weight: .semibold))
                            }
                            if let author = content.authorName, !author.isEmpty {
                                Text(author).font(.system(size: width * 0.06, weight: .medium)).lineLimit(1)
                            }
                        } else {
                            Text(content.title)
                                .font(.system(size: width * 0.13, weight: .bold, design: .serif))
                                .lineLimit(3).minimumScaleFactor(0.65)
                            if !content.subtitle.isEmpty {
                                Text(content.subtitle).font(.system(size: width * 0.059, weight: .medium)).lineLimit(2).opacity(0.75)
                            }
                        }
                    }
                    .padding(.horizontal, width * 0.085)
                    .padding(.bottom, width * 0.10)
                }
            }
            .foregroundStyle(ink)
            .clipShape(.rect(cornerRadius: width * 0.045))
            .overlay(RoundedRectangle(cornerRadius: width * 0.045).strokeBorder(.white.opacity(0.22), lineWidth: 1))
        }
    }

    @ViewBuilder private func artwork(width: CGFloat) -> some View {
        if let url = BoxCoverArtwork.url(for: content) {
            if let loadedArtwork {
                if let image = loadedArtwork[url] {
                    Color.clear.overlay { image.resizable().scaledToFill() }.clipped()
                } else {
                    placeholder(width: width)
                }
            } else {
                Color.clear.overlay {
                    AsyncImage(request: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholder(width: width)
                    }
                }.clipped()
            }
        } else {
            placeholder(width: width)
        }
    }

    private func placeholder(width: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [tint, tint.opacity(0.4), .black.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if content.kind == .soundtrack {
                Circle().fill(.black.opacity(0.3)).overlay {
                    Circle().strokeBorder(.white.opacity(0.12), lineWidth: width * 0.035).padding(width * 0.1)
                }
                .frame(width: width * 0.68, height: width * 0.68)
            }
            Image(systemName: symbol)
                .font(.system(size: width * 0.26, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}
