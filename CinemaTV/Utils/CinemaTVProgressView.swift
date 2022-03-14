//
//  CinemaTVProgressView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 06/12/21.
//

import SwiftUI

struct CinemaTVProgressView: View {
    var body: some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 10) {
                ProgressView()
                Text("carregando")
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        } else {
            // Fallback on earlier versions
            VStack(spacing: 10) {
                ProgressView()
                Text("carregando")
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

struct CinemaTVProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CinemaTVProgressView().previewLayout(.fixed(width: 100, height: 100))
    }
}
