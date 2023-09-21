//
//  WidgetView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/04/23.
//

import WidgetKit
import SwiftUI

struct WidgetMediumView: View {
    var data: WidgetEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comming Soon")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 20) {
                ForEach(data.widgetData.prefix(3), id: \.self) { value in
                    //MARK: - AsyncImage not working with Widgets
                    Group {
                        if let url = URL(string: Constants.basePosters + value.poster_path), let imageData = try? Data(contentsOf: url),
                           let uiImage = UIImage(data: imageData) {
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .cornerRadius(8)
                        }
                        else {
                            Image("placeholder-image")
                        }
                    }
                }
            }
        }
        .containerBackground(
            .linearGradient(
            colors: [.black, .gray],
            startPoint: .top,
            endPoint: .bottom),
            for: .widget
        )
    }
}

struct WidgetMediumView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetMediumView(
            data:
                WidgetEntry(
                    date: Date(),
                    widgetData: Array(
                        repeating: MovieResultModel(
                            id: 0,
                            title: "title",
                            description: "BLa BLA Bla BLa BLA Bla",
                            poster_path: "/wRnbWt44nKjsFPrqSmwYki5vZtF.jpg"
                        ),
                        count: 6
                    )
                )
        )
        .previewContext(WidgetPreviewContext(family: WidgetFamily.systemMedium))
    }
}
