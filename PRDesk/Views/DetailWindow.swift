//
//  DetailWindow.swift
//  PRDesk
//
//  Created by PR Desk
//

import AppKit
import SwiftUI

/// Main detail window showing full PR information with tabs
class DetailWindowController: NSWindowController {
    convenience init(initialTab: DetailView.DetailTab = .myPRs) {
        // Calculate dynamic window size based on screen dimensions
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = screenFrame.width * 0.85
        let height = screenFrame.height * 0.85

        // Create a standard macOS window (not NSPanel)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "PR Desk"
        window.center()
        window.setFrameAutosaveName("DetailWindow")

        // Set minimum window size to prevent it from being too small
        window.minSize = NSSize(width: 800, height: 600)

        // Create SwiftUI content
        let detailView = DetailView(initialTab: initialTab)
        let hostingController = NSHostingController(rootView: detailView)
        window.contentViewController = hostingController

        self.init(window: window)
    }
}

/// SwiftUI view for the detail window content with tabs
struct DetailView: View {
    enum DetailTab: String, CaseIterable {
        case myPRs = "My PRs"
        case reviewRequested = "PRs I'm Tagged In"
    }

    @State private var selectedTab: DetailTab

    init(initialTab: DetailTab = .myPRs) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MyPRsDetailView()
                .tabItem {
                    Text("My PRs")
                }
                .tag(DetailTab.myPRs)

            ReviewRequestedDetailView()
                .tabItem {
                    Text("PRs I'm Tagged In")
                }
                .tag(DetailTab.reviewRequested)
        }
        .tabViewStyle(.automatic)
    }
}

/// ViewModel for detail views
class DetailPRListViewModel: ObservableObject {
    @Published var pullRequests: [PullRequest] = []
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?

    private let dataStore = PRDataStore()
    let listType: ListType  // Made public for DetailPRListView access
    private var notificationObserver: NSObjectProtocol?

    enum ListType {
        case myPRs
        case reviewRequested
    }

    init(listType: ListType) {
        self.listType = listType
        loadPRs()

        // Observe data change notifications
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .prDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("[DetailViewModel] Received PRDataDidChange notification - reloading data")
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
            switch listType {
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
}

/// Detail view for "My PRs" tab
struct MyPRsDetailView: View {
    @StateObject private var viewModel = DetailPRListViewModel(listType: .myPRs)

    var body: some View {
        DetailPRListView(viewModel: viewModel, title: "My PRs")
    }
}

/// Detail view for "PRs I'm Tagged In" tab
struct ReviewRequestedDetailView: View {
    @StateObject private var viewModel = DetailPRListViewModel(listType: .reviewRequested)

    var body: some View {
        DetailPRListView(viewModel: viewModel, title: "PRs I'm Tagged In")
    }
}

/// Shared list view component for detail tabs
struct DetailPRListView: View {
    @ObservedObject var viewModel: DetailPRListViewModel
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Header with last update time and Preferences button
            HStack {
                if let lastUpdate = viewModel.lastUpdateTime {
                    Text("Last updated \(timeAgoString(from: lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Preferences button for accessing settings
                Button(action: {
                    openPreferences()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text("Preferences")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            Divider()

            if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.pullRequests.isEmpty {
                emptyStateView
            } else {
                prListView
            }
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
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No PRs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prListView: some View {
        List {
            ForEach(viewModel.pullRequests) { pr in
                DetailRowView(pullRequest: pr, widgetType: widgetTypeFromListType)
            }
        }
        .listStyle(.inset)
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

    private var widgetTypeFromListType: WidgetType {
        switch viewModel.listType {
        case .myPRs:
            return .myPRs
        case .reviewRequested:
            return .reviewRequested
        }
    }

    private func openPreferences() {
        // Call the AppDelegate's showPreferences method
        NSApp.sendAction(#selector(AppDelegate.showPreferences(_:)), to: nil, from: nil)
    }
}

/// Detailed PR row component showing all PR information
struct DetailRowView: View {
    let pullRequest: PullRequest
    let widgetType: WidgetType
    private let promptConfigService = PromptConfigService()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and PR number
            HStack(alignment: .top) {
                Text("#\(pullRequest.number)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(pullRequest.title)
                    .font(.headline)
                    .lineLimit(2)
            }

            // Repository
            HStack {
                Image(systemName: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(pullRequest.repositoryFullName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Status
            HStack {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }

            // Last activity
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Last updated \(relativeTime(from: pullRequest.updatedAt))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Author
            HStack {
                Image(systemName: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Author: \(pullRequest.author.login)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Action buttons
            HStack(spacing: 12) {
                // Open in Claude button (text is configurable via prompts.json)
                Button(action: {
                    openInClaude()
                }) {
                    HStack {
                        Image(systemName: "terminal")
                        Text(promptConfigService.getConfig().buttonText)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Open in GitHub button
                Button(action: {
                    openInGitHub()
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Open in GitHub")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .opacity(pullRequest.needsAction ? 1.0 : 0.6)
    }

    // MARK: - Status helpers

    private var statusText: String {
        if pullRequest.isDraft {
            return "Draft"
        }
        switch pullRequest.state {
        case "OPEN":
            return "Open"
        case "CLOSED":
            return "Closed"
        case "MERGED":
            return "Merged"
        default:
            return pullRequest.state
        }
    }

    private var statusIcon: String {
        if pullRequest.isDraft {
            return "pencil.circle"
        }
        switch pullRequest.state {
        case "OPEN":
            return "circle"
        case "CLOSED":
            return "xmark.circle"
        case "MERGED":
            return "checkmark.circle"
        default:
            return "circle"
        }
    }

    private var statusColor: Color {
        if pullRequest.isDraft {
            return .gray
        }
        switch pullRequest.state {
        case "OPEN":
            return .green
        case "CLOSED":
            return .red
        case "MERGED":
            return .purple
        default:
            return .secondary
        }
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func openInClaude() {
        // Generate prompt using ClaudeIntegrationService
        let service = ClaudeIntegrationService()
        let prompt = service.generatePrompt(pr: pullRequest, widgetType: widgetType)

        // Launch Terminal with Claude Code in the repository directory
        let launcher = TerminalLauncher()
        launcher.launchClaude(with: prompt, repositoryName: pullRequest.repositoryFullName)

        print("[Claude Button] Launched Claude Code for PR #\(pullRequest.number) in repo \(pullRequest.repositoryFullName)")
    }

    private func openInGitHub() {
        // Open the PR URL in the default browser
        if let url = URL(string: pullRequest.url) {
            NSWorkspace.shared.open(url)
            print("[GitHub Button] Opened PR #\(pullRequest.number) in browser: \(pullRequest.url)")
        } else {
            print("[GitHub Button] Invalid URL for PR #\(pullRequest.number): \(pullRequest.url)")
        }
    }
}
