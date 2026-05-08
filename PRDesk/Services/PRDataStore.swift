//
//  PRDataStore.swift
//  PRDesk
//
//  Local storage for pull request data
//

import Foundation

/// Notification posted when PR data is updated
extension Notification.Name {
    static let prDataDidChange = Notification.Name("PRDataDidChange")
}

enum PRDataStoreError: Error {
    case fileAccessFailed
    case invalidData
}

/// Manages local storage of PR data
class PRDataStore {
    private let fileManager = FileManager.default
    private let myPRsFileName = "myPRs.json"
    private let reviewRequestedPRsFileName = "reviewRequestedPRs.json"
    private let lastUpdateFileName = "lastUpdate.json"

    /// Returns the storage directory (Application Support)
    private var storageDirectory: URL {
        get throws {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let prDeskDir = appSupport.appendingPathComponent("PRDesk", isDirectory: true)

            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: prDeskDir.path) {
                try fileManager.createDirectory(at: prDeskDir, withIntermediateDirectories: true)
            }

            return prDeskDir
        }
    }

    /// Saves PRs authored by the current user
    func saveMyPRs(_ prs: [PullRequest]) throws {
        let fileURL = try storageDirectory.appendingPathComponent(myPRsFileName)
        try savePRs(prs, to: fileURL)
        try saveLastUpdateTime()

        // Notify observers that data has changed
        NotificationCenter.default.post(name: .prDataDidChange, object: nil)
        print("[DataStore] Posted PRDataDidChange notification (myPRs)")
    }

    /// Saves PRs where the current user is requested as reviewer
    func saveReviewRequestedPRs(_ prs: [PullRequest]) throws {
        let fileURL = try storageDirectory.appendingPathComponent(reviewRequestedPRsFileName)
        try savePRs(prs, to: fileURL)
        try saveLastUpdateTime()

        // Notify observers that data has changed
        NotificationCenter.default.post(name: .prDataDidChange, object: nil)
        print("[DataStore] Posted PRDataDidChange notification (reviewRequestedPRs)")
    }

    /// Loads PRs authored by the current user
    func loadMyPRs() throws -> [PullRequest] {
        let fileURL = try storageDirectory.appendingPathComponent(myPRsFileName)
        return try loadPRs(from: fileURL)
    }

    /// Loads PRs where the current user is requested as reviewer
    func loadReviewRequestedPRs() throws -> [PullRequest] {
        let fileURL = try storageDirectory.appendingPathComponent(reviewRequestedPRsFileName)
        return try loadPRs(from: fileURL)
    }

    /// Loads the last update time
    func loadLastUpdateTime() -> Date? {
        do {
            let fileURL = try storageDirectory.appendingPathComponent(lastUpdateFileName)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let timestamp = try decoder.decode(Date.self, from: data)
            return timestamp
        } catch {
            return nil
        }
    }

    /// Saves PRs to a file
    private func savePRs(_ prs: [PullRequest], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(prs)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw PRDataStoreError.fileAccessFailed
        }
    }

    /// Loads PRs from a file
    private func loadPRs(from url: URL) throws -> [PullRequest] {
        // Return empty array if file doesn't exist
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let prs = try decoder.decode([PullRequest].self, from: data)
            return prs
        } catch {
            throw PRDataStoreError.invalidData
        }
    }

    /// Saves the current time as last update time
    private func saveLastUpdateTime() throws {
        let fileURL = try storageDirectory.appendingPathComponent(lastUpdateFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let timestamp = Date()
        let data = try encoder.encode(timestamp)
        try data.write(to: fileURL, options: [.atomic])
    }
}
