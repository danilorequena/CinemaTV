//
//  CreditsView.swift
//  CinemaTV
//
//  Created by Jessica Bigal on 05/04/23.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack {
            Image("tmdb")
                .imageScale(.medium)
                .foregroundColor(.accentColor)
                .padding(.vertical)
                .scaledToFill()
            Link(LC.creditsName.text, destination: URL(string: "https://www.themoviedb.org")!)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .underline()
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            Text(LC.creditsParagraph.text)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .padding([.top, .leading, .trailing])
                .padding(.bottom, 1)
        }
        .padding()
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
            .preferredColorScheme(.dark)
        CreditsView()
            .preferredColorScheme(.light)
    }
}
