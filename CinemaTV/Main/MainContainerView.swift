//
//  MainContainerView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct MainContainerView: View {
    @State private var discoveryViewModel = DiscoverySheetViewModel()
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var startWithSearch = false
    @Namespace private var sheetAnimation

    private let detents: Set<PresentationDetent> = [
        .height(80),   // Collapsed - just search bar
        .medium,       // Half screen
        .large         // Full screen
    ]

    var body: some View {
        ZStack {
            NewHomeView(sheetDetent: $sheetDetent)
        }
        .sheet(isPresented: .constant(true)) {
            sheetContent
                .presentationDetents(detents, selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled()
        }
        .task {
            // Load discovery data when app starts
            await discoveryViewModel.loadAllData()
        }
        .onChange(of: sheetDetent) { _, newValue in
            // Reset search mode when collapsing
            if newValue == .height(80) {
                startWithSearch = false
            }
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if sheetDetent == .height(80) {
            collapsedContent
        } else {
            expandedContent
        }
    }

    @ViewBuilder
    private var collapsedContent: some View {
        VStack {
            CollapsedSearchView {
                startWithSearch = true
                withAnimation(.spring(response: 0.4)) {
                    sheetDetent = .medium
                }
            }
            .padding(.top, 16)
            Spacer()
        }
        .glassEffectID("sheet", in: sheetAnimation)
    }

    @ViewBuilder
    private var expandedContent: some View {
        DiscoverySheetView(
            viewModel: discoveryViewModel,
            selectedDetent: $sheetDetent,
            startWithSearch: startWithSearch
        )
        .glassEffectID("sheet", in: sheetAnimation)
    }
}

#Preview {
    MainContainerView()
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self, TVShowWatchingModel.self])
}
