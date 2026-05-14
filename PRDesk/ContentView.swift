//
//  ContentView.swift
//  PRDesk
//
//  Created by PR Desk
//

import SwiftUI

/// Widget type enum to differentiate between "My PRs" and "PRs I'm Tagged In"
enum WidgetType {
    case myPRs
    case reviewRequested

    var title: String {
        switch self {
        case .myPRs:
            return "My PRs"
        case .reviewRequested:
            return "PRs I'm Tagged In"
        }
    }
}

/// ViewModel for managing PR list state
class PRListViewModel: ObservableObject {
    @Published var pullRequests: [PullRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?

    private let dataStore = PRDataStore()
    private let widgetType: WidgetType
    private var notificationObserver: NSObjectProtocol?

    init(widgetType: WidgetType) {
        self.widgetType = widgetType
        loadPRs()

        // Observe data change notifications
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .prDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("[ViewModel] Received PRDataDidChange notification - reloading data")
            self?.loadPRs()
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func loadPRs() {
        errorMessage = nil

        do {
            switch widgetType {
            case .myPRs:
                pullRequests = try dataStore.loadMyPRs()
            case .reviewRequested:
                pullRequests = try dataStore.loadReviewRequestedPRs()
            }
            lastUpdateTime = dataStore.loadLastUpdateTime()
        } catch {
            errorMessage = "Failed to load PRs: \(error.localizedDescription)"
            pullRequests = []
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch fresh data from GitHub
            try await PRRefreshService().refresh()
            // Reload from disk to update UI
            try loadPRsFromDisk()
            isLoading = false
        } catch {
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func loadPRsFromDisk() throws {
        switch widgetType {
        case .myPRs:
            pullRequests = try dataStore.loadMyPRs()
        case .reviewRequested:
            pullRequests = try dataStore.loadReviewRequestedPRs()
        }
    }
}

struct ContentView: View {
    let widgetType: WidgetType
    @StateObject private var viewModel: PRListViewModel

    init(widgetType: WidgetType = .myPRs) {
        self.widgetType = widgetType
        _viewModel = StateObject(wrappedValue: PRListViewModel(widgetType: widgetType))
    }

    var body: some View {
        ZStack {
            // Translucent dark background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(widgetType.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        if let lastUpdate = viewModel.lastUpdateTime {
                            Text("Updated \(timeAgoString(from: lastUpdate))")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()
                    .background(Color.white.opacity(0.2))

                // PR List or Empty State
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.pullRequests.isEmpty {
                    emptyStateView
                } else {
                    prListView
                }
            }
        }
        .frame(width: 300, height: calculateHeight())
    }

    // MARK: - Dynamic Height Calculation

    /// Calculate widget height based on number of PRs
    /// Header: ~50px, Each PR row: ~70px, Empty/Loading/Error states: ~100px
    private func calculateHeight() -> CGFloat {
        let headerHeight: CGFloat = 50
        let rowHeight: CGFloat = 70
        let emptyStateHeight: CGFloat = 100
        let maxHeight: CGFloat = 400
        let minHeight: CGFloat = 150

        let contentHeight: CGFloat
        if viewModel.isLoading || viewModel.errorMessage != nil || viewModel.pullRequests.isEmpty {
            // Loading, error, or empty state
            contentHeight = emptyStateHeight
        } else {
            // Calculate based on number of PRs
            let prCount = CGFloat(viewModel.pullRequests.count)
            contentHeight = prCount * rowHeight + 16 // 16px for padding
        }

        let totalHeight = headerHeight + contentHeight
        return min(max(totalHeight, minHeight), maxHeight)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading PRs...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow.opacity(0.8))
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))
            Text("No PRs")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.pullRequests) { pr in
                    PRRowView(pullRequest: pr)
                        .onTapGesture {
                            handlePRClick(pr)
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func handlePRClick(_ pr: PullRequest) {
        // Post notification to AppDelegate to show detail window
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowDetailWindow"),
            object: nil,
            userInfo: ["widgetType": widgetType]
        )
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(days)d ago"
        }
    }
}

/// Individual PR row component
struct PRRowView: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(pullRequest.title)
                .font(.subheadline)
                .foregroundColor(titleColor)
                .lineLimit(2)

            // Repository
            Text(pullRequest.repositoryFullName)
                .font(.caption)
                .foregroundColor(repoColor)

            // Last updated (relative time)
            Text(relativeTime(from: pullRequest.updatedAt))
                .font(.caption2)
                .foregroundColor(timeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(pullRequest.needsAction ? 1.0 : 0.5)
    }

    // MARK: - Computed Colors

    /// Color hierarchy for text elements (row opacity handles dimming)
    private var titleColor: Color {
        .white
    }

    private var repoColor: Color {
        .white.opacity(0.6)
    }

    private var timeColor: Color {
        .white.opacity(0.5)
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// SwiftUI wrapper for NSVisualEffectView
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
