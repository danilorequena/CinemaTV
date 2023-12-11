//
//  WidgetLargeView.swift
//  CinemaTVWidgetExtension
//
//  Created by Danilo Requena on 08/07/23.
//

import WidgetKit
import SwiftUI

struct WidgetLargeView: View {
    var data: WidgetEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Comming Soon")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(data.widgetData.prefix(5), id: \.self) { value in
                    //MARK: - AsyncImage not working with Widgets
                    Group {
                        HStack(alignment: .top, spacing: 10) {
                            if let url = URL(string: Constants.basePosters + value.poster_path), let imageData = try? Data(contentsOf: url),
                               let uiImage = UIImage(data: imageData) {
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 60)
                                    .cornerRadius(8)
                            } else {
                                Image("placeholder-image")
                            }
                            
                            VStack(alignment: .leading) {
                                Text(value.title)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text(value.description ?? "")
                                    .font(.callout)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.bottom, 4)
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

struct WidgetLargeView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetLargeView(
            data:
                WidgetEntry(
                    date: Date(),
                    widgetData: [
                        MovieResultModel(
                            id: 234,
                            title: "Jobs",
                            description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                            poster_path: "/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg"
                        ),
                        MovieResultModel(
                            id: 234,
                            title: "Jobs",
                            description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                            poster_path: "/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg"
                        ),
                        MovieResultModel(
                            id: 234,
                            title: "Jobs",
                            description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                            poster_path: "/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg"
                        ),
                        MovieResultModel(
                            id: 234,
                            title: "Jobs",
                            description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                            poster_path: "/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg"
                        ),
                        MovieResultModel(
                            id: 234,
                            title: "Jobs",
                            description: "BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla BLa BLA Bla",
                            poster_path: "/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg"
                        )
                    ]
                )
        )
        .previewContext(WidgetPreviewContext(family: WidgetFamily.systemLarge))
    }
}


