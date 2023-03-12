//
//  CinemaTVWidget.swift
//  CinemaTVWidget
//
//  Created by Danilo Requena on 30/07/22.
//

import WidgetKit
import SwiftUI
import Kingfisher

struct Model: TimelineEntry, Decodable {
    var date: Date
    var widgetData: [MovieResultModel]
}

struct MovieModel: Codable {
    let results: [MovieResultModel]
}

struct MovieResultModel: Codable, Hashable, Identifiable {
    let id: Int
    let title: String
    let poster_path: String
}

struct Provider: TimelineProvider {
    typealias Entry = Model
    
    func placeholder(in context: Context) -> Model {
        return Model(
            date: Date(),
            widgetData: [
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                )
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Model) -> Void) {
        let loadingData = Model(
            date: Date(),
            widgetData: [
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                )
            ]
        )
        completion(loadingData)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Model>) -> Void) {
        //        MovieStore.shared.fetchNowMovies(from: .upcoming) { result in
        //            switch result {
        //            case .success(let movies):
        //                let date = Date()
        //                let data = Model(date: date, widgetData: movies.results)
        //                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)
        //                let timeline = Timeline(entries: [data], policy: .after(nextUpdate!))
        //                completion(timeline)
        //            case .failure(let error):
        //                print(error)
        //            }
        //        }
        getData { (modelData) in
            let date = Date()
            let data = Model(date: date, widgetData: modelData.results)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: date)
            let timeline = Timeline(entries: [data], policy: .after(nextUpdate!))
            completion(timeline)
        }
    }
    
    func getData(completion: @escaping (MovieModel) -> ()) {
        let url = "https://api.themoviedb.org/3/movie/upcoming?api_key=ddf20e1d6a0147313cfd3b4ac419e373&include_adult=false"
        let session = URLSession(configuration: .default)
        session.dataTask(with: URL(string: url)!) { (data, _, error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            
            do {
                let jsonData = try Utils.jsonDecoder.decode(MovieModel.self, from: data!)
                completion(jsonData)
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
    }
}

struct CinemaTVWidgetView: View {
    var data: Model
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Comming Soon")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 16)
                    .foregroundColor(.white)
                
                HStack(alignment: .top, spacing: 16) {
                    ForEach(data.widgetData.prefix(3), id: \.self) { value in
                        KFImage(URL(string: Constants.basePosters + value.poster_path))
                            .resizable()
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 4)
        }
        .background(
            LinearGradient(
                colors: [.black, .gray],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

@main
struct MainWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Comming Soon", provider: Provider()) { data in
            CinemaTVWidgetView(data: data)
        }
        .description("Comming Soon")
        .configurationDisplayName("Comming Soon")
        .supportedFamilies([.systemMedium])
    }
}

struct UpcomingWidget_Previews: PreviewProvider {
    static var previews: some View {
        CinemaTVWidgetView(data: Model(
            date: Date(),
            widgetData: Array(
                repeating: MovieResultModel(
                    id: 0,
                    title: "title",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                count: 6
            )
        )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
