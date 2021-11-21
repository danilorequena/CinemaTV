//
//  DetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel = DetailViewModel()
    var movieID: Int?
    
    var body: some View {
        ScrollView {
            ZStack {
                if let image = URL(string: viewModel.detailMovie?.backdropPath ?? ""), let imageData = try? Data(contentsOf: image), let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                } else {
                    Image("placeholder-image")
                }
                VStack {
                    Text(viewModel.detailMovie?.overview ?? "")
                }
            }
            .task {
                await viewModel.fetchDetail(movieID: movieID ?? 0)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
