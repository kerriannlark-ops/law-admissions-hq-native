import Foundation
import SwiftData

@Model
final class ApplicantProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var highestLSAT: Int = 147
    var cumulativeGPA: Double = 3.62
    var applicationTiming: String = "mid"
    var scholarshipPriority: String = "high"
    var retakeCapacity: String = "high"
    var formatPreference: String = "hybrid"
    var regionPriority: String = "ohio"
    var careerFocus: String = "public-interest"
    var packageReadiness: String = "mixed"
    var costSensitivity: String = "high"
    var applicationMonth: String = "October"
    var timelinePressure: String = "manageable"
    var createdAt: Date = .now

    init() {}
}

@Model
final class SchoolEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var program: String = ""
    var format: String = "hybrid"
    var region: String = "ohio"
    var notes: String = ""
    var medianLSAT: Int?
    var medianGPA: Double?
    var createdAt: Date = .now

    init(name: String, program: String, format: String, region: String, notes: String) {
        self.name = name
        self.program = program
        self.format = format
        self.region = region
        self.notes = notes
    }
}

@Model
final class Dossier {
    @Attribute(.unique) var id: UUID = UUID()
    var personalStatement: String = ""
    var resumeText: String = ""
    var transcriptNotes: String = "Kent State A.A. completed 2023; Clark Atlanta University B.A. Political Science, Magna Cum Laude, completed 2024."
    var workSummary: String = "Legal Assistant at MDK Legal; prior legal support experience; notary business; research and leadership background."
    var recommenderPlan: String = "One academic recommender and one legal/professional recommender."
    var schoolNotes: String = "Ohio-focused; wants part-time, hybrid, or online-friendly programs with realistic access."
    var weakPoints: String = "Highest LSAT 147. Statement needs concrete legal moments. Chronology should stay clean and intentional."
    var optionalEssayIdeas: String = "Resilience, rights advocacy, systems thinking, leadership, business-building discipline."
    var updatedAt: Date = .now

    init() {}
}

@Model
final class GeneratedPrompt {
    @Attribute(.unique) var id: UUID = UUID()
    var section: String = ""
    var title: String = ""
    var body: String = ""
    var createdAt: Date = .now

    init(section: String, title: String, body: String) {
        self.section = section
        self.title = title
        self.body = body
    }
}

@Model
final class AIReview {
    @Attribute(.unique) var id: UUID = UUID()
    var section: String = ""
    var headline: String = ""
    var strengthsText: String = ""
    var risksText: String = ""
    var fixesText: String = ""
    var confidence: String = "AI-generated"
    var sourceType: String = "OpenAI Responses API"
    var rawText: String = ""
    var createdAt: Date = .now

    init(section: String, headline: String, strengthsText: String = "", risksText: String = "", fixesText: String = "", confidence: String = "AI-generated", sourceType: String = "OpenAI Responses API", rawText: String) {
        self.section = section
        self.headline = headline
        self.strengthsText = strengthsText
        self.risksText = risksText
        self.fixesText = fixesText
        self.confidence = confidence
        self.sourceType = sourceType
        self.rawText = rawText
    }
}

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var section: String = "dashboard"
    var isComplete: Bool = false
    var createdAt: Date = .now

    init(title: String, section: String) {
        self.title = title
        self.section = section
    }
}

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case dashboard
    case dossier
    case essays
    case resumeAddendum
    case interviewRecs
    case schoolStrategy
    case promptStudio
    case sourcesMethod

    var id: String { rawValue }
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .dossier: return "Dossier"
        case .essays: return "Essays"
        case .resumeAddendum: return "Resume + Addendum"
        case .interviewRecs: return "Interview + Recs"
        case .schoolStrategy: return "School Strategy"
        case .promptStudio: return "Prompt Studio"
        case .sourcesMethod: return "Sources + Method"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "rectangle.grid.2x2"
        case .dossier: return "folder.text.magnifyingglass"
        case .essays: return "square.and.pencil"
        case .resumeAddendum: return "doc.text"
        case .interviewRecs: return "person.2"
        case .schoolStrategy: return "graduationcap"
        case .promptStudio: return "text.badge.plus"
        case .sourcesMethod: return "books.vertical"
        }
    }
}

enum PromptMode: String, CaseIterable, Identifiable {
    case fullReview = "Full package review"
    case statement = "Personal statement revision"
    case resumeAddendum = "Resume + addendum review"
    case interview = "Interview prep"
    case schoolStrategy = "School strategy"

    var id: String { rawValue }
}

enum AIReviewScope: String, CaseIterable, Identifiable {
    case dossier
    case statement
    case resumeAddendum
    case interview
    case schoolStrategy

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
