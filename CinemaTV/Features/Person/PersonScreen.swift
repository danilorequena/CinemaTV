//
//  PersonScreen.swift
//  CinemaTV
//
//  Perfil de pessoa: foto, pills de nascimento, bio, Known For e a
//  filmografia completa (Filmes/Séries) com picker glass. Substitui PersonView.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct PersonScreen: View {
    private enum FilmographyKind: Hashable {
        case movies
        case shows
    }

    @Environment(\.tmdbClient) private var client
    @State private var model = PersonScreenModel()
    @State private var filmographyKind: FilmographyKind = .movies

    let personID: Int

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                LoadingStateView {
                    VStack(spacing: DSSpacing.lg) {
                        Circle().fill(.quaternary).frame(width: 140, height: 140)
                        Text(verbatim: "Placeholder Name").font(.dsSectionTitle)
                    }
                    .padding(.top, DSSpacing.xxl)
                }
            case .loaded(let content):
                loadedContent(content)
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.retry(client: client, personID: personID) }
                }
                .padding(.top, DSSpacing.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load(client: client, personID: personID)
        }
    }

    private func loadedContent(_ content: PersonScreenModel.Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(spacing: DSSpacing.md) {
                PosterImage(path: content.person.profilePath, kind: .profile)
                    .frame(width: 140, height: 140)
                    .clipShape(.circle)
                Text(verbatim: content.person.name)
                    .font(.dsSectionTitle)
                if let department = content.person.knownForDepartment {
                    Text(verbatim: department)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
                let pills = personPills(content.person)
                if !pills.isEmpty {
                    // Local de nascimento pode ser longo; rola em vez de
                    // estourar a largura.
                    ScrollView(.horizontal) {
                        InfoPillRow(pills: pills)
                            .padding(.horizontal, DSSpacing.lg)
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DSSpacing.lg)

            if let biography = content.person.biography, !biography.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    SectionHeader("Biography")
                    // Sem lineLimit: a bio já vive num ScrollView e o corte
                    // em 8 linhas escondia conteúdo (pior em Dynamic Type
                    // grande), sem nenhum "read more" para expandir.
                    Text(verbatim: biography)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, DSSpacing.lg)
                }
            }

            if !content.knownFor.isEmpty {
                MediaCarousel(title: "Known For", items: content.knownFor, zoomScope: "knownFor")
            }

            filmography(content)
        }
        .padding(.bottom, DSSpacing.xxl)
    }

    // MARK: - Filmography

    @ViewBuilder
    private func filmography(_ content: PersonScreenModel.Content) -> some View {
        let hasBoth = !content.movies.isEmpty && !content.shows.isEmpty
        let items = filmographyItems(content)

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                SectionHeader("Filmography")
                if hasBoth {
                    GlassSegmentedPicker(
                        selection: $filmographyKind,
                        segments: [
                            .init(FilmographyKind.movies, label: Text("Movies")),
                            .init(FilmographyKind.shows, label: Text("TV Shows"))
                        ]
                    )
                    .padding(.horizontal, DSSpacing.lg)
                }
                LazyVStack(alignment: .leading, spacing: DSSpacing.md) {
                    ForEach(items) { item in
                        let selection = MediaSelection(item: item, scope: "filmography")
                        NavigationLink(value: selection) {
                            FilmographyRow(item: item, zoomSourceID: selection.sourceID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .animation(DSMotion.standard, value: filmographyKind)
            }
        }
    }

    /// Segmento vazio não trava a seção: cai na lista que existir.
    private func filmographyItems(_ content: PersonScreenModel.Content) -> [MediaItem] {
        switch filmographyKind {
        case .movies: content.movies.isEmpty ? content.shows : content.movies
        case .shows: content.shows.isEmpty ? content.movies : content.shows
        }
    }

    // MARK: - Pills

    private func personPills(_ person: PersonDetails) -> [InfoPillRow.Pill] {
        var pills: [InfoPillRow.Pill] = []
        if let birthday = formattedDate(person.birthday) {
            pills.append(.init(id: "birthday", text: "\(birthday)", systemImage: "birthday.cake"))
        }
        if let deathday = formattedDate(person.deathday) {
            pills.append(.init(id: "deathday", text: "✝ \(deathday)"))
        } else if let age = age(of: person) {
            pills.append(.init(id: "age", text: "\(age) years old"))
        }
        if let place = person.placeOfBirth, !place.isEmpty {
            pills.append(.init(id: "place", text: "\(place)", systemImage: "mappin.and.ellipse"))
        }
        return pills
    }

    private func parseDate(_ iso: String?) -> Date? {
        guard let iso else { return nil }
        return try? Date(iso, strategy: .iso8601.year().month().day())
    }

    private func formattedDate(_ iso: String?) -> String? {
        // O parse ISO cai em meia-noite UTC; formatar em GMT evita a data
        // regredir um dia em fusos negativos.
        parseDate(iso)?.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))
    }

    private func age(of person: PersonDetails) -> Int? {
        guard let birth = parseDate(person.birthday) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.dateComponents([.year], from: birth, to: .now).year
    }
}

// MARK: - Row da filmografia

/// Linha compacta: poster + título + ano · personagem, com zoom source.
private struct FilmographyRow: View {
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    let item: MediaItem
    var zoomSourceID: String?

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            PosterImage(path: item.posterPath, kind: .thumbnail)
                .frame(width: 48)
                .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.title)
                    .font(.dsCardTitle)
                    .lineLimit(1)
                Text(verbatim: subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        [item.releaseYear, item.character.flatMap { $0.isEmpty ? nil : $0 }]
            .compactMap(\.self)
            .joined(separator: " · ")
    }
}

@MainActor
@Observable
final class PersonScreenModel {
    struct Content: Sendable {
        let person: PersonDetails
        let knownFor: [MediaItem]
        let movies: [MediaItem]
        let shows: [MediaItem]
    }

    private(set) var state: LoadState<Content> = .idle

    func load(client: TMDBClient, personID: Int) async {
        if case .loaded = state { return }
        state = .loading
        do {
            async let person: PersonDetails = client.fetch(.person(id: personID))
            async let credits: PersonCredits = client.fetch(.personCredits(id: personID))

            // combined_credits repete o mesmo título quando a pessoa tem
            // mais de um papel; dedupe por tipo+id (ids colidem entre
            // filmes e séries).
            var seen = Set<String>()
            let unique = try await credits.cast
                .filter { $0.mediaType != .person }
                .filter { seen.insert("\($0.mediaType.rawValue)-\($0.id)").inserted }

            let byDate: (MediaItem, MediaItem) -> Bool = {
                ($0.releaseDate ?? "") > ($1.releaseDate ?? "")
            }

            state = .loaded(
                Content(
                    person: try await person,
                    knownFor: Array(unique.sorted { $0.voteAverage > $1.voteAverage }.prefix(10)),
                    movies: unique.filter { $0.mediaType == .movie }.sorted(by: byDate),
                    shows: unique.filter { $0.mediaType == .tvShow }.sorted(by: byDate)
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func retry(client: TMDBClient, personID: Int) async {
        state = .idle
        await load(client: client, personID: personID)
    }
}
