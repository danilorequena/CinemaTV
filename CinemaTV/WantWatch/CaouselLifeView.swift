//
//  CaouselLifeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/08/23.
//

import SwiftUI

struct CarouselLifeView: View {
    var value: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                VStack {
                    Image(systemName: "movieclapper")
                    Text(value)
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .frame(width: 200)
                
                //TODO: - Aqui ficará o counter de séries
                VStack {
                    Image(systemName: "tv")
                    Text("Você já assistiu 10 horas e 12 minutos de séries na sua vida!!!")
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .frame(width: 200)
                
                //TODO: - Aqui ficará o counter de Totel de conteudo
                VStack {
                    HStack {
                        Image(systemName: "tv")
                        Image(systemName: "movieclapper")
                    }
                    Text("Você já consumiu um total de 100 horas de conteudo!!!")
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .frame(width: 200)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    CarouselLifeView(value: "Você já assistiu 10 horas e 12 minutos de séries na sua vida!!!")
        .previewLayout(.fixed(width: 420, height: 260))
}
