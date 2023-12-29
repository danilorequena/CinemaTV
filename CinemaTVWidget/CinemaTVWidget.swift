//
//  CinemaTVWidget.swift
//  CinemaTVWidget
//
//  Created by Danilo Requena on 30/07/22.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    typealias Entry = WidgetEntry
    let service = MovieStore.shared
    
    func placeholder(in context: Context) -> WidgetEntry {
        return WidgetEntry(
            date: Date(),
            widgetData: [
                MovieResultModel(
                    id: 0,
                    title: "Dr Strange",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "Dr Strange",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "Dr Strange",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                )
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let loadingData = WidgetEntry(
            date: Date(),
            widgetData: [
                MovieResultModel(
                    id: 0,
                    title: "Dr Strange",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "Steve Jobs",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                ),
                MovieResultModel(
                    id: 0,
                    title: "Iron man",
                    description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                    poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                )
            ]
        )
        completion(loadingData)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        getData { (modelData) in
            let date = Date()
            let data = WidgetEntry(date: date, widgetData: modelData.results)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: date)
            let timeline = Timeline(entries: [data], policy: .after(nextUpdate!))
            completion(timeline)
        }
    }
    
    func getData(completion: @escaping (MovieModel) -> ()) {
        let url = "https://api.themoviedb.org/3/movie/upcoming?api_key=\(Constants.apikey)&language=en&include_adult=false"
        let session = URLSession(configuration: .default)
        session.dataTask(with: URL(string: url)!) { (data, _, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            do {
                let jsonData = try Utils.jsonDecoder.decode(MovieModel.self, from: data!)
                completion(jsonData)
            } catch {
                print(error)
            }
        }.resume()
    }
}

@main
struct BundleWidgets: WidgetBundle {
    var body: some Widget {
        MainWidget()
    }
}

struct MainWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Comming Soon", provider: Provider()) { data in
            CinemaTVWidgetView(data: data)
        }
        .configurationDisplayName(LC.commingSoon.text)
        .description(LC.commingSoonDescription.text)
        .supportedFamilies(
            [
                .systemMedium,
                .systemSmall,
                .systemLarge,
                .accessoryRectangular
            ]
        )
    }
}

struct CinemaTVWidgetView: View {
    var data: WidgetEntry
    @Environment(\.widgetFamily) var size
    var body: some View {
        ZStack {
            switch size {
            case .systemSmall:
                WidgetSmallView(data: data)
            case .systemMedium:
                WidgetMediumView(data: data)
            case .accessoryRectangular:
                AccessoryRetangularWidgetView(data: data)
            case .systemLarge:
                WidgetLargeView(data: data)
            default:
                WidgetSmallView(data: data)
            }
        }
    }
    
    struct UpcomingWidget_Previews: PreviewProvider {
        static var previews: some View {
            CinemaTVWidgetView(data: WidgetEntry(
                date: Date(),
                widgetData: Array(
                    repeating: MovieResultModel(
                        id: 0,
                        title: "title",
                        description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                        poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                    ),
                    count: 6
                )
            )
            )
            .previewContext(WidgetPreviewContext(family: WidgetFamily.systemLarge))
        }
    }
}
