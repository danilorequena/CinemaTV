//
//  Plataaforms+Extension.swift
//  CinemaTV
//
//  Created by Danilo Requena on 8/1/24.
//

import SwiftUI

extension View {
    func iOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
        #if os(iOS)
        return modifier(self)
        #else
        return self
        #endif
    }
}
