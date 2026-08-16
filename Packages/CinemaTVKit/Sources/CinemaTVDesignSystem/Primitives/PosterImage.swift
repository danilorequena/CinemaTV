//
//  PosterImage.swift
//  CinemaTVKit
//
//  Único ponto de carregamento de imagem do app. AsyncImage(request:) com
//  cache por request (iOS 27) — substitui o ImageLoader legado com NSCache.
//  O app aplica .asyncImageURLSession na raiz para configurar o URLCache.
//

import SwiftUI
import CinemaTVCore

public struct PosterImage: View {
    public enum Kind {
        /// Poster 2:3 (rails, grids).
        case poster
        /// Backdrop 16:9 (hero, header do detail).
        case backdrop
        /// Foto de perfil circular (elenco).
        case profile
        /// Thumbnail pequena (rows de lista).
        case thumbnail

        var tmdbSize: TMDBImage.Size {
            switch self {
            case .poster: .poster
            case .backdrop: .backdrop
            case .profile: .profile
            case .thumbnail: .thumbnail
            }
        }

        var aspectRatio: CGFloat? {
            switch self {
            case .poster, .thumbnail: 2 / 3
            case .backdrop: 16 / 9
            case .profile: 1
            }
        }
    }

    private let path: String?
    private let kind: Kind
    private let fillsContainer: Bool
    private let clipsContent: Bool

    /// fillsContainer: ignora o aspect ratio do kind e preenche o espaço
    /// dado pelo container (hero cards, headers full-bleed).
    /// clipsContent: com false, a sobra do aspect-fill transborda o frame e
    /// o clip fica por conta do caller — necessário quando a imagem sofre
    /// offset depois (parallax do hero), senão o offset expõe faixa vazia.
    public init(path: String?, kind: Kind, fillsContainer: Bool = false, clipsContent: Bool = true) {
        self.path = path
        self.kind = kind
        self.fillsContainer = fillsContainer
        self.clipsContent = clipsContent
    }

    public var body: some View {
        if let url = TMDBImage.url(path: path, size: kind.tmdbSize) {
            let image = AsyncImage(request: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholder
            }

            if fillsContainer, clipsContent {
                Color.clear
                    .overlay { image }
                    .clipped()
            } else if fillsContainer {
                Color.clear
                    .overlay { image }
            } else {
                image
                    .aspectRatio(kind.aspectRatio, contentMode: .fit)
                    .clipped()
            }
        } else if fillsContainer {
            placeholder
        } else {
            placeholder
                .aspectRatio(kind.aspectRatio, contentMode: .fit)
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                // Decorativo: o símbolo era anunciado como "movie clapper"
                // pelo VoiceOver nos cards sem imagem.
                Image(systemName: kind == .profile ? "person.fill" : "movieclapper")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
    }
}

public extension View {
    /// Sessão compartilhada de imagens com URLCache dimensionado; aplicar na
    /// raiz do app e dos widgets.
    func dsImagePipeline() -> some View {
        asyncImageURLSession(DSImagePipeline.session)
    }
}

public enum DSImagePipeline {
    public static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }()
}

#Preview("Kinds", traits: .sizeThatFitsLayout) {
    HStack(spacing: DSSpacing.lg) {
        PosterImage(path: nil, kind: .poster)
            .frame(width: 120)
            .clipShape(.rect(cornerRadius: DSRadius.poster))
        PosterImage(path: nil, kind: .profile)
            .frame(width: 72)
            .clipShape(.circle)
    }
    .padding()
}
