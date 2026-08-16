//
//  CastCarousel.swift
//  CinemaTVKit
//
//  Rail de elenco — substitui CastView/CastCell/CastListView. O tap navega
//  com um MediaItem de tipo .person, resolvido pelo app.
//

import SwiftUI
import CinemaTVCore

public struct CastCarousel: View {
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    private let members: [CastMember]
    private let title: Text

    /// title: Text (não LocalizedStringKey) para a string resolver no
    /// catálogo do chamador (ex.: "Guest Stars" do app).
    public init(members: [CastMember], title: Text? = nil) {
        self.members = members
        self.title = title ?? Text("Cast", bundle: .module)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader(text: title)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: DSSpacing.md) {
                    ForEach(members) { member in
                        // MediaSelection (não MediaItem): pareia o card com o
                        // sourceID para a PersonScreen abrir com zoom.
                        let selection = MediaSelection(item: member.personItem, scope: "cast")
                        NavigationLink(value: selection) {
                            PersonCard(member: member)
                                .modifier(ZoomSourceModifier(id: selection.sourceID, namespace: zoomNamespace))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, DSSpacing.lg)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }
}

public struct PersonCard: View {
    // Larguras escalam com o texto: em tamanhos de acessibilidade o nome
    // ficava truncado ("Carrie-Anne…") no frame fixo de 88pt.
    @ScaledMetric(relativeTo: .caption) private var photoSize: CGFloat = 80
    @ScaledMetric(relativeTo: .caption) private var cardWidth: CGFloat = 88

    private let member: CastMember

    public init(member: CastMember) {
        self.member = member
    }

    public var body: some View {
        VStack(spacing: DSSpacing.sm) {
            PosterImage(path: member.profilePath, kind: .profile)
                .frame(width: photoSize, height: photoSize)
                .clipShape(.circle)
            VStack(spacing: 2) {
                // Sem reservesSpace: nome de 1 linha deixava uma linha vazia
                // entre nome e personagem. O LazyHStack alinha pelo topo.
                Text(verbatim: member.name)
                    .font(.dsCaption)
                    .lineLimit(2)
                if let character = member.character {
                    Text(verbatim: character)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: cardWidth)
        .accessibilityElement(children: .combine)
        // Inclui o personagem: só o nome escondia metade da informação do
        // card para quem usa VoiceOver.
        .accessibilityLabel(Text(verbatim: member.character.map { "\(member.name), \($0)" } ?? member.name))
    }
}

public extension CastMember {
    /// Valor de navegação para a tela de pessoa.
    var personItem: MediaItem {
        MediaItem(
            id: id,
            title: name,
            overview: character ?? "",
            posterPath: profilePath,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: .person
        )
    }
}

#Preview {
    NavigationStack {
        CastCarousel(members: [
            CastMember(id: 1, name: "Keanu Reeves", character: "Neo", profilePath: nil, order: 0),
            CastMember(id: 2, name: "Carrie-Anne Moss", character: "Trinity", profilePath: nil, order: 1)
        ])
    }
}
