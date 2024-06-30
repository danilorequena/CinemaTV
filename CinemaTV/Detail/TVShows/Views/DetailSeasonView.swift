import SwiftUI
import SwiftData

struct DetailSeasonView: View {
    @StateObject var viewModel: SeasonViewModel
    @State private var isChecked = false
    @State private var isWatched = false
    @Environment(\.modelContext) private var modelContext
    
    @State private var isOn = false
    var body: some View {
        VStack {
            if let data = viewModel.data {
                List {
                    Section {
                        HStack {
                            AsyncImage(url: URL(string: Constants.basePosters + (data.posterPath))) { image in
                                image
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            } placeholder: {
                                Image("placeholder-image")
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            }
                            
                            VStack{
                                Text(data.name)
                                Text(data.overview)
                                    .lineLimit(8)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Section("episodes") {
                        ForEach(data.episodes) { episode in
                            DisclosureGroup(episode.name ?? "") {
                                EpisodeCellView(
                                    imagePath: Constants.basePosters + (episode.stillPath ?? ""),
                                    overview: episode.overview ?? ""
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(action: {
                                    isWatched.toggle()
                                }, label: {
                                    Label("Watched", image: "checkmark")
                                })
                                .background(isWatched ? .green : .gray)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
                Button("Save Episodes") {
//                    saveData(with: data)
                    saveTestData()
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadSeasonDetail()
        }
    }
    
    private func saveTestData() {
            do {
                // Criar um novo TV Show
                let tvShow = TVShowDataModel(
                    id: 123,
                    title: "Title",
                    overview: "Overview",
                    releaseDate: Date(),
                    imagePath: "bla"
                )
                
                // Criar uma nova Season associada ao TV Show
                let season = SeasonDataModel(
                    seasonNumber: 1,
                    releaseDate: Date()
//                    tvShow: tvShow
                )
                
                // Testar a adição de um único episódio
                let episode = EpisodeDataModel(
                    title: "Test Episode",
                    duration: 45,
                    releaseDate: "11/11/11"
//                    season: season
                )
                
                // Adicionar o episódio à temporada
                season.episodes?.append(episode)
                
                // Adicionar a temporada ao TV Show
                tvShow.seasons?.append(season)
                
                // Inserir o TV Show no contexto
                modelContext.insert(tvShow)
                
                // Salvar o contexto
                try modelContext.save()
                print("Dados de teste salvos com sucesso!")
            } catch {
                print("Erro ao salvar dados de teste: \(error.localizedDescription)")
            }
        }
    
    private func saveData(with seasonDetail: SeasonModel) {
        let tvShow = TVShowDataModel(
            id: 123,
            title: "Example Title", // Ajuste conforme necessário
            overview: "Bla",
            releaseDate: Date(), // Ajuste conforme necessário
            imagePath: ""
        )
        
        let season = SeasonDataModel(
            id: Int(seasonDetail.id) ?? 0,
            seasonNumber: seasonDetail.seasonNumber,
            releaseDate: DateFormatter.yyyyMMdd.date(from: seasonDetail.airDate) ?? Date()
//            tvShow: tvShow
        )
        
        for episodeData in seasonDetail.episodes {
            guard let episodeID = episodeData.id,
                  let episodeTitle = episodeData.name,
                  let episodeDuration = episodeData.runtime,
                  let episodeReleaseDateString = episodeData.airDate else {
                continue
            }
            
            let episode = EpisodeDataModel(
                id: episodeID, 
                title: episodeTitle,
                duration: episodeDuration,
                releaseDate: episodeReleaseDateString
//                season: season
            )
            
            // Adiciona o episódio à temporada
            season.episodes?.append(episode)
        }
        
        tvShow.seasons?.append(season)
        modelContext.insert(tvShow)
        
        do {
            try modelContext.save()
            print("Dados salvos com sucesso!")
        } catch {
            print("Erro ao salvar dados: \(error.localizedDescription)")
        }
    }
}

struct DetailSeasonView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSeasonView(
            viewModel: SeasonViewModel(
                tvShowID: 84958,
                tvshowSeasonNumber: 1
            )
        )
        .modelContainer(for: [TVShowDataModel.self, SeasonDataModel.self, EpisodeDataModel.self])
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 5.0)
                .stroke(lineWidth: 2)
                .frame(width: 25, height: 25)
                .cornerRadius(5.0)
                .overlay {
                    Image(systemName: configuration.isOn ? "checkmark" : "")
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
            configuration.label
        }
    }
}
