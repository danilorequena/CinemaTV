//
//  ReviewCardRenderer.swift
//  CinemaTV
//
//  Exporta o ReviewShareCard como UIImage via ImageRenderer. O poster é
//  pré-carregado pela mesma sessão/cache do PosterImage (AsyncImage não
//  renderiza dentro do ImageRenderer), normalmente um cache hit.
//

import SwiftUI
import UIKit
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
enum ReviewCardRenderer {
    static func loadPoster(path: String?) async -> UIImage? {
        guard let url = TMDBImage.url(path: path, size: .poster) else { return nil }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        guard let (data, _) = try? await DSImagePipeline.session.data(for: request) else { return nil }
        return UIImage(data: data)
    }

    /// Escala fixa 3x sobre o card de 360×450 → 1080×1350, qualidade de
    /// feed independente do device.
    static func render(title: String, rating: Double, reviewText: String, poster: UIImage?) -> UIImage? {
        let card = ReviewShareCard(
            title: title,
            rating: rating,
            reviewText: reviewText,
            poster: poster.map(Image.init(uiImage:))
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
