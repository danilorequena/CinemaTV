//
//  AccessoryRetangularWidgetView.swift
//  CinemaTVWidgetExtension
//
//  Created by Danilo Requena on 07/04/23.
//

import WidgetKit
import SwiftUI

struct AccessoryRetangularWidgetView: View {
    var data: WidgetEntry
    var body: some View {
        HStack {
            Image("ic_comming_soon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(data.widgetData.prefix(3)) { movie in
                    Text(movie.title)
                        .font(.footnote)
                        .fontWidth(.condensed)
                }
            }
        }
    }
}

struct AccessoryRetangularWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        AccessoryRetangularWidgetView(
            data:
                WidgetEntry(
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
        .previewContext(WidgetPreviewContext(family: WidgetFamily.accessoryRectangular))
    }
    }
