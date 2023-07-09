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
        VStack(alignment: .leading, spacing: 15) {
            Text("Comming Soon")
                .font(.largeTitle)
                .fontWeight(.regular)
                .padding(.leading, 16)
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
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.black, .gray],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
