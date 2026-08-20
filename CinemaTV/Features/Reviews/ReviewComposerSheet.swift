//
//  ReviewComposerSheet.swift
//  CinemaTV
//
//  Composer do review pessoal: estrelas inteiras + texto livre,
//  preview ao vivo do card exportado e ShareLink com a imagem final.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct ReviewComposerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: MediaItem

    @State private var rating: Double = 0
    @State private var text = ""
    @State private var hasExistingReview = false
    @State private var posterImage: UIImage?
    @State private var shareImage: UIImage?

    private var store: ReviewStore {
        ReviewStore(context: modelContext)
    }

    /// Chave do re-render: qualquer mudança visível regenera a imagem.
    private struct RenderKey: Equatable {
        var rating: Double
        var text: String
        var hasPoster: Bool
    }

    private var renderKey: RenderKey {
        RenderKey(rating: rating, text: text, hasPoster: posterImage != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    StarRatingInput(rating: $rating)
                        .padding(.top, DSSpacing.md)

                    editor

                    if let shareImage {
                        sharePreview(shareImage)
                    }

                    if hasExistingReview {
                        Button("Delete Review", role: .destructive) {
                            deleteReview()
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.bottom, DSSpacing.xxl)
            }
            .navigationTitle(Text(verbatim: item.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Review") { saveReview() }
                        .disabled(rating < 1)
                }
            }
            .task {
                hydrate()
                posterImage = await ReviewCardRenderer.loadPoster(path: item.posterPath)
            }
            .task(id: renderKey) {
                renderShareImage()
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Subviews

    private var editor: some View {
        TextEditor(text: $text)
            .frame(minHeight: 120)
            .scrollContentBackground(.hidden)
            .padding(DSSpacing.sm)
            .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("What we thought")
                        .foregroundStyle(.tertiary)
                        .padding(DSSpacing.md)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private func sharePreview(_ image: UIImage) -> some View {
        VStack(spacing: DSSpacing.md) {
            // Preview é a imagem exportada de verdade — o que se vê é o
            // que sai no share sheet.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: DSRadius.card))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 8)

            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview(item.title, image: Image(uiImage: image))
            ) {
                Label("Share Review", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.glassProminent)
        }
    }

    // MARK: - Actions

    private func hydrate() {
        guard let review = try? store.review(forMovieID: item.id) else { return }
        hasExistingReview = true
        if let storedRating = review.rating {
            rating = ReviewStore.normalizedRating(storedRating)
        }
        text = review.reviewText ?? ""
    }

    private func saveReview() {
        do {
            try store.saveReview(for: item, rating: rating, text: text)
            dismiss()
        } catch {
            assertionFailure("Review save failed: \(error)")
        }
    }

    private func deleteReview() {
        do {
            try store.deleteReview(movieID: item.id)
            dismiss()
        } catch {
            assertionFailure("Review delete failed: \(error)")
        }
    }

    private func renderShareImage() {
        guard rating >= 1 else {
            shareImage = nil
            return
        }
        shareImage = ReviewCardRenderer.render(
            title: item.title,
            rating: rating,
            reviewText: text,
            poster: posterImage
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ReviewComposerSheet(item: .dsPreview)
        .modelContainer(try! ModelContainerFactory.makeInMemory())
}
