import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

@MainActor
enum AppIconService {
    static func apply(style: String) async throws {
        #if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let iconName = style == "premium" ? "PremiumAppIcon" : nil
        try await withCheckedThrowingContinuation { continuation in
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        #elseif canImport(AppKit)
        let imageName = style == "premium" ? "IconPremium" : "IconStandard"
        if let image = NSImage(named: NSImage.Name(imageName)) {
            NSApplication.shared.applicationIconImage = image
        }
        #endif
    }
}

struct WorkspaceBackupSnapshot: Codable {
    struct ProfileData: Codable {
        var highestLSAT: Int
        var cumulativeGPA: Double
        var applicationTiming: String
        var scholarshipPriority: String
        var retakeCapacity: String
        var formatPreference: String
        var regionPriority: String
        var careerFocus: String
        var packageReadiness: String
        var costSensitivity: String
        var applicationMonth: String
        var timelinePressure: String
    }

    struct DossierData: Codable {
        var personalStatement: String
        var resumeText: String
        var transcriptNotes: String
        var workSummary: String
        var recommenderPlan: String
        var schoolNotes: String
        var weakPoints: String
        var optionalEssayIdeas: String
    }

    struct SchoolData: Codable {
        var name: String
        var program: String
        var format: String
        var region: String
        var notes: String
        var medianLSAT: Int?
        var medianGPA: Double?
    }

    struct PromptData: Codable {
        var section: String
        var title: String
        var body: String
        var createdAt: Date
    }

    struct ReviewData: Codable {
        var section: String
        var headline: String
        var strengthsText: String
        var risksText: String
        var fixesText: String
        var confidence: String
        var sourceType: String
        var rawText: String
        var createdAt: Date
    }

    struct TaskData: Codable {
        var title: String
        var section: String
        var isComplete: Bool
        var createdAt: Date
    }

    var version: String
    var exportedAt: Date
    var profile: ProfileData
    var dossier: DossierData
    var schools: [SchoolData]
    var prompts: [PromptData]
    var reviews: [ReviewData]
    var tasks: [TaskData]
}

enum WorkspaceBackupService {
    static func exportJSON(snapshot: WorkspaceBackupSnapshot) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        return String(decoding: data, as: UTF8.self)
    }

    static func importJSON(_ json: String) throws -> WorkspaceBackupSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkspaceBackupSnapshot.self, from: Data(json.utf8))
    }
}
