//
//  CinemaTVWidget.swift
//  CinemaTVWidget
//
//  Created by Danilo Requena on 30/07/22.
//

import WidgetKit
import SwiftUI

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
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)
            let timeline = Timeline(entries: [data], policy: .after(nextUpdate!))
            completion(timeline)
        }
    }
    
    func getData(completion: @escaping (MovieModel) -> ()) {
        let url = "https://api.themoviedb.org/3/movie/upcoming?api_key=ddf20e1d6a0147313cfd3b4ac419e373&include_adult=false"
        let session = URLSession(configuration: .default)
        session.dataTask(with: URL(string: url)!) { (data, _, err) in
            if err != nil {
                print(err)
                return
            }
            
            do {
                let jsonData = try JSONDecoder().decode(MovieModel.self, from: data!)
                completion(jsonData)
            } catch {
                print(err)
            }
        }.resume()
    }
}

struct CinemaTVWidgetView: View {
    var data: Model
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Widget")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(alignment: .top, spacing: 16) {
                ForEach(data.widgetData.prefix(4), id: \.self) { value in
                    AsyncImage(url: URL(string: Constants.basePosters + value.poster_path))
                }
            }
        }
    }
}

@main
struct MainWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Upcoming", provider: Provider()) { data in
            CinemaTVWidgetView(data: data)
        }
        .description("Upcoming")
        .configurationDisplayName("Upcomings")
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
