#if DEBUG && os(iOS)
import SwiftUI

// Visual exploration only. No persistence, playback, CloudKit or published links.
enum BoxesDirection: String, CaseIterable, Identifiable {
    case collector, editorial, mixtape
    var id: Self { self }
    var title: String {
        switch self {
        case .collector: "Colecionador"
        case .editorial: "Editorial"
        case .mixtape: "Mixtape"
        }
    }
    var background: Color {
        switch self {
        case .collector: Color(red: 0.055, green: 0.061, blue: 0.067)
        case .editorial: Color(red: 0.96, green: 0.94, blue: 0.88)
        case .mixtape: Color(red: 0.095, green: 0.075, blue: 0.15)
        }
    }
    var ink: Color { self == .editorial ? Color(white: 0.12) : Color(white: 0.95) }
    var accent: Color {
        self == .mixtape ? Color(red: 0.98, green: 0.58, blue: 0.48) : DSColor.accent
    }
    var scheme: ColorScheme { self == .editorial ? .light : .dark }
}

enum BoxesArtworkKind { case space, arrival, dark, office }

/// Deterministic cover illustrations keep Canvas previews entirely offline.
struct BoxesArtwork: View {
    let kind: BoxesArtworkKind

    private var colors: [Color] {
        switch kind {
        case .space: [Color(red: 0.18, green: 0.32, blue: 0.40), .black]
        case .arrival: [Color(red: 0.72, green: 0.72, blue: 0.57), Color(red: 0.20, green: 0.28, blue: 0.27)]
        case .dark: [Color(red: 0.20, green: 0.34, blue: 0.32), .black]
        case .office: [Color(red: 0.77, green: 0.40, blue: 0.22), Color(red: 0.27, green: 0.16, blue: 0.17)]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Canvas { context, size in
                    for index in 0..<65 {
                        let x = CGFloat((index * 73 + 19) % 293) / 293 * size.width
                        let y = CGFloat((index * 47 + 13) % 257) / 257 * size.height
                        let dot = CGRect(x: x, y: y, width: index.isMultiple(of: 7) ? 2 : 1, height: 1)
                        context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.35)))
                    }
                }
                switch kind {
                case .space:
                    Circle()
                        .fill(RadialGradient(colors: [.black, .black, Color(red: 0.94, green: 0.74, blue: 0.42), .clear], center: .center, startRadius: w * 0.15, endRadius: w * 0.29))
                        .frame(width: w * 0.75, height: w * 0.75)
                        .offset(x: w * 0.12, y: -h * 0.06)
                    Ellipse().fill(.white.opacity(0.7))
                        .frame(width: w * 1.1, height: 3).blur(radius: 4)
                        .rotationEffect(.degrees(-18)).offset(y: -h * 0.05)
                    mountain(width: w, height: h).fill(Color(white: 0.10))
                case .arrival:
                    Ellipse().fill(.black.opacity(0.86))
                        .frame(width: w * 0.23, height: h * 0.56)
                        .rotationEffect(.degrees(12)).offset(y: -h * 0.06)
                    Ellipse().fill(.white.opacity(0.26)).frame(width: w * 1.5, height: h * 0.2)
                        .blur(radius: 18).offset(y: h * 0.20)
                case .dark:
                    ForEach(0..<9) { index in
                        Rectangle().fill(.black.opacity(0.50))
                            .frame(width: CGFloat(5 + index % 3 * 3), height: h)
                            .rotationEffect(.degrees(Double(index % 3 * 6 - 6)))
                            .offset(x: CGFloat(index - 4) * w / 8)
                    }
                    RoundedRectangle(cornerRadius: 30).fill(.black)
                        .frame(width: w * 0.50, height: h * 0.37).offset(y: h * 0.3)
                    Image(systemName: "figure.stand").font(.system(size: w * 0.17))
                        .foregroundStyle(.yellow).offset(y: h * 0.3)
                case .office:
                    ForEach(0..<6) { index in
                        Rectangle().fill(.white.opacity(0.14))
                            .frame(width: w, height: 2).offset(y: CGFloat(index - 3) * h / 8)
                    }
                    Image(systemName: "mug.fill").font(.system(size: w * 0.37))
                        .foregroundStyle(Color(white: 0.9)).rotationEffect(.degrees(-8))
                }
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
            }.clipped()
        }
        .accessibilityHidden(true)
    }

    private func mountain(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: height * 0.83))
            path.addLine(to: CGPoint(x: width * 0.34, y: height * 0.71))
            path.addLine(to: CGPoint(x: width * 0.57, y: height * 0.86))
            path.addLine(to: CGPoint(x: width, y: height * 0.68))
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
    }
}

struct BoxesCover: View {
    var title = "ALÉM\nDO TEMPO"
    var subtitle = "UMA EDIÇÃO DE MARINA"
    var kind: BoxesArtworkKind = .space
    var spine = true

    var body: some View {
        GeometryReader { geometry in
        HStack(spacing: 0) {
            if spine {
                Rectangle().fill(LinearGradient(colors: [.black, Color(white: 0.30), .black], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 15)
                    .overlay {
                        Text("CINEMATV  /  BOX 001").font(.system(size: 7, weight: .bold, design: .monospaced))
                            .tracking(2).fixedSize().rotationEffect(.degrees(-90)).foregroundStyle(.white.opacity(0.6))
                    }
            }
            BoxesArtwork(kind: kind)
                .overlay(alignment: .topLeading) {
                    Text("CINEMATV BOXES").font(.system(size: max(5, geometry.size.width * 0.035), weight: .semibold)).tracking(1.6)
                        .lineLimit(1).minimumScaleFactor(0.5).padding(12)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title).font(.system(size: min(28, geometry.size.width * 0.12), weight: .black, design: .serif)).tracking(-0.4)
                            .lineLimit(2).minimumScaleFactor(0.4)
                        Rectangle().frame(width: 32, height: 2).foregroundStyle(DSColor.accent)
                        Text(subtitle).font(.system(size: 7, weight: .medium)).tracking(0.8)
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }.padding(12)
                }
        }
        .foregroundStyle(.white)
        .clipShape(.rect(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.white.opacity(0.15)))
        }
    }
}

struct BoxesPreviewEntry: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
    let kind: BoxesArtworkKind
    static let samples: [Self] = [
        .init(id: 1, title: "Interestelar", detail: "Filme · 2014 · Christopher Nolan", symbol: "film", kind: .space),
        .init(id: 2, title: "O trailer que me ganhou", detail: "Trailer · Interestelar · 2min 19s", symbol: "play.rectangle", kind: .space),
        .init(id: 3, title: "Cornfield Chase", detail: "Música · Hans Zimmer", symbol: "music.note", kind: .space),
        .init(id: 4, title: "A Chegada", detail: "Filme · 2016 · Denis Villeneuve", symbol: "film", kind: .arrival),
        .init(id: 5, title: "O começo é o fim", detail: "Episódio · Dark · T2 E8", symbol: "tv", kind: .dark)
    ]
}

struct BoxesEntryRow: View {
    let entry: BoxesPreviewEntry
    var body: some View {
        HStack(spacing: 13) {
            BoxesArtwork(kind: entry.kind).frame(width: 46, height: 60).clipShape(.rect(cornerRadius: 6))
                .overlay { if entry.symbol == "music.note" { Image(systemName: entry.symbol).foregroundStyle(.white) } }
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title).font(.subheadline.weight(.semibold))
                Text(entry.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: entry.symbol).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
