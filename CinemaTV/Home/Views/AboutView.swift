//
//  AboutView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 13/11/22.
//

import SwiftUI
import AVKit
import WebKit

struct AboutView: View {
    var body: some View {
        VStack {
            VStack(spacing: 24) {
                Text(LC.aboutTheAppTitle.text)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                
                Text(LC.aboutTheAppMessage.text)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
