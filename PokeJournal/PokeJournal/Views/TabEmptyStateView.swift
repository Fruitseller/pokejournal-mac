//
//  TabEmptyStateView.swift
//  PokéJournal
//

import SwiftUI

/// Vertically and horizontally centered empty state for tab content shown inside
/// `GameDetailView`'s ScrollView. Use this for every "no data yet" placeholder so
/// the visual style stays consistent across tabs.
struct TabEmptyStateView: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey?

    init(_ title: LocalizedStringKey, systemImage: String, description: LocalizedStringKey? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let description {
                Text(description)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerRelativeFrame(.vertical)
    }
}

#Preview {
    TabEmptyStateView(
        "Keine Sessions gefunden",
        systemImage: "calendar.badge.exclamationmark",
        description: "Sobald du Sessions in deinem Vault hast, erscheinen sie hier."
    )
}
