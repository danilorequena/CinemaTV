//
//  StateViews.swift
//  CinemaTVKit
//
//  Estados assíncronos consistentes. Substituem o CinemaTVProgressView e os
//  blocos `if let` ad-hoc das telas antigas.
//

import SwiftUI
import CinemaTVCore

/// Estado de carga padrão dos ViewModels do redesign.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

/// Skeleton: a tela passa um placeholder representativo e recebe shimmer
/// via redacted.
public struct LoadingStateView<Skeleton: View>: View {
    private let skeleton: Skeleton

    public init(@ViewBuilder skeleton: () -> Skeleton) {
        self.skeleton = skeleton()
    }

    public var body: some View {
        skeleton
            .redacted(reason: .placeholder)
            // O skeleton é decorativo: sem ignore, o VoiceOver navegava
            // pelos placeholders redacted um a um.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Loading", bundle: .module))
    }
}

public struct ErrorStateView: View {
    private let message: String
    private let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text("Something went wrong", bundle: .module)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(message)
        } actions: {
            // Forma com label: separado — o thunk de previews do Xcode falha
            // com "ambiguous __designTimeSelection" no trailing closure duplo.
            Button {
                retry()
            } label: {
                Text("Try Again", bundle: .module)
            }
            .buttonStyle(.glassProminent)
        }
    }
}

public struct EmptyStateView: View {
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let systemImage: String

    public init(title: LocalizedStringKey, message: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

#Preview("Error") {
    ErrorStateView(message: "Network error. Check your connection.", retry: {})
}

#Preview("Empty") {
    EmptyStateView(
        title: "No Movies Yet",
        message: "Movies you add to your watchlist appear here.",
        systemImage: "bookmark"
    )
}
