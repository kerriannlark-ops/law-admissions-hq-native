import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class WorkspaceStore {
    private enum DefaultsKey {
        static let demoWorkspaceSeeded = "lawAdmissionsDemoWorkspaceSeeded"
    }

    let modelContext: ModelContext

    var profile: ApplicantProfile
    var dossier: Dossier
    var schools: [SchoolEntry]
    var prompts: [GeneratedPrompt]
    var reviews: [AIReview]
    var tasks: [TaskItem]

    var selectedSection: WorkspaceSection = .dashboard
    var promptMode: PromptMode = .fullReview
    var targetSchool: String = "Cleveland State / Capital / Dayton"
    var customNotes: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        let profiles = (try? modelContext.fetch(FetchDescriptor<ApplicantProfile>())) ?? []
        if let existing = profiles.first {
            self.profile = existing
        } else {
            let created = ApplicantProfile()
            modelContext.insert(created)
            self.profile = created
        }

        let dossiers = (try? modelContext.fetch(FetchDescriptor<Dossier>())) ?? []
        if let existing = dossiers.first {
            self.dossier = existing
        } else {
            let created = Dossier()
            modelContext.insert(created)
            self.dossier = created
        }

        let fetchedSchools = (try? modelContext.fetch(FetchDescriptor<SchoolEntry>(sortBy: [SortDescriptor(\.name)]))) ?? []
        self.schools = fetchedSchools
        self.prompts = ((try? modelContext.fetch(FetchDescriptor<GeneratedPrompt>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])
        self.reviews = ((try? modelContext.fetch(FetchDescriptor<AIReview>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])
        self.tasks = ((try? modelContext.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])

        let shouldSeedDemo = !UserDefaults.standard.bool(forKey: DefaultsKey.demoWorkspaceSeeded) && shouldInstallDemoWorkspace()
        if shouldSeedDemo {
            seedDemoWorkspace(force: true)
            UserDefaults.standard.set(true, forKey: DefaultsKey.demoWorkspaceSeeded)
        } else if schools.isEmpty {
            seedDefaultSchools()
        }

        save()
        seedRecommendedTasksIfNeeded()
    }

    func save() {
        dossier.updatedAt = .now
        try? modelContext.save()
        refreshCollections()
    }

    func refreshCollections() {
        schools = ((try? modelContext.fetch(FetchDescriptor<SchoolEntry>(sortBy: [SortDescriptor(\.name)]))) ?? [])
        prompts = ((try? modelContext.fetch(FetchDescriptor<GeneratedPrompt>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])
        reviews = ((try? modelContext.fetch(FetchDescriptor<AIReview>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])
        tasks = ((try? modelContext.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? [])
    }

    func savePrompt(title: String, body: String, section: WorkspaceSection) {
        modelContext.insert(GeneratedPrompt(section: section.rawValue, title: title, body: body))
        save()
    }

    func saveAIReview(scope: AIReviewScope, payload: AIReviewPayload) {
        modelContext.insert(AIReview(section: scope.rawValue, headline: payload.headline, strengthsText: payload.strengthsText, risksText: payload.risksText, fixesText: payload.fixesText, confidence: payload.confidence, sourceType: payload.sourceType, rawText: payload.rawText))
        save()
    }

    func latestReview(for scope: AIReviewScope) -> AIReview? {
        reviews.first(where: { $0.section == scope.rawValue })
    }

    func addTask(_ title: String, section: WorkspaceSection) {
        guard !tasks.contains(where: { $0.title == title }) else { return }
        modelContext.insert(TaskItem(title: title, section: section.rawValue))
        save()
    }

    func toggleTask(_ task: TaskItem) {
        task.isComplete.toggle()
        save()
    }

    func seedRecommendedTasksIfNeeded(force: Bool = false) {
        guard force || tasks.isEmpty else { return }
        if force {
            clear(tasks)
        }
        let summary = RuleEngine.makeDashboard(profile: profile, dossier: dossier, schools: schools)
        for item in summary.actions.prefix(4) {
            modelContext.insert(TaskItem(title: item, section: WorkspaceSection.dashboard.rawValue))
        }
        save()
    }

    func exportBackupJSON() throws -> String {
        try WorkspaceBackupService.exportJSON(snapshot: makeSnapshot())
    }

    func importBackupJSON(_ json: String) throws {
        let snapshot = try WorkspaceBackupService.importJSON(json)
        apply(snapshot: snapshot)
        UserDefaults.standard.set(true, forKey: DefaultsKey.demoWorkspaceSeeded)
    }

    func seedDemoWorkspace(force: Bool = true) {
        if force {
            clear(schools)
            clear(prompts)
            clear(reviews)
            clear(tasks)
        }

        profile.highestLSAT = 147
        profile.cumulativeGPA = 3.62
        profile.applicationTiming = "mid"
        profile.scholarshipPriority = "high"
        profile.retakeCapacity = "high"
        profile.formatPreference = "hybrid"
        profile.regionPriority = "ohio"
        profile.careerFocus = "public-interest"
        profile.packageReadiness = "mixed"
        profile.costSensitivity = "high"
        profile.applicationMonth = "October"
        profile.timelinePressure = "manageable"

        dossier.personalStatement = "I am drawn to law because I have repeatedly seen how institutional rules shape whether people can actually access stability, dignity, and meaningful relief. Working in legal environments clarified that I am most engaged when I am helping translate complicated systems into concrete next steps for real people. My goal now is to build the legal training to move from support and observation into advocacy, analysis, and long-term problem solving."
        dossier.resumeText = "Legal Assistant, MDK Legal — manage legal files, document preparation, deadline tracking, client communication support, and administrative coordination in an active legal environment.\nNotary Business Owner — coordinate scheduling, identity verification, document workflow, and client-facing service operations.\nResearch / leadership experience — academic writing, structured analysis, and project ownership."
        dossier.transcriptNotes = "Kent State University — Associate degree completed 2023. Clark Atlanta University — B.A. Political Science, Magna Cum Laude, completed 2024. Academic path should be framed as progression, not fragmentation."
        dossier.workSummary = "Current legal assistant role provides daily exposure to file management, legal documentation, deadlines, discretion, and client-facing professionalism."
        dossier.recommenderPlan = "1 academic recommender who can speak to writing and analysis; 1 legal/professional recommender who can speak to reliability, judgment, and responsibility."
        dossier.schoolNotes = "Primary targets: Cleveland State Online JD, Capital Law part-time, Dayton hybrid. Focus on Ohio, flexible formats, and strong professional fit."
        dossier.weakPoints = "Highest LSAT 147. Statement must stay concrete and law-specific. Need clean explanation of academic chronology if asked."
        dossier.optionalEssayIdeas = "Resilience, systems thinking, rights advocacy, legal professionalism, business discipline, balancing work and academic ambition."

        seedDefaultSchools()

        let demoPrompt = GeneratedPrompt(section: WorkspaceSection.promptStudio.rawValue, title: "Demo Full Review Prompt", body: "Review my full law admissions package and tell me the strongest narrative theme, biggest liability, and three concrete revisions I should make before submitting to Ohio part-time programs.")
        let demoReview = AIReview(section: AIReviewScope.dossier.rawValue, headline: "Demo dossier read", strengthsText: "Professional legal exposure, strong academic signal, disciplined regional strategy.", risksText: "LSAT 147 narrows margin for error. Statement must carry more specificity.", fixesText: "Sharpen why-law language, reduce resume rehash, tighten school-specific tailoring.", confidence: "Rule-based demo", sourceType: "Seeded workspace", rawText: "Overall read: promising file with real legal substance, but the LSAT means the written materials must be unusually disciplined and concrete.")
        let demoTasks = [
            TaskItem(title: "Tighten the first paragraph of the personal statement around one concrete legal or institutional moment.", section: WorkspaceSection.essays.rawValue),
            TaskItem(title: "Confirm official medians and optional essay requirements for Cleveland State, Capital, and Dayton.", section: WorkspaceSection.schoolStrategy.rawValue),
            TaskItem(title: "Draft a concise LSAT explanation for interview use only, not as an excuse-heavy addendum.", section: WorkspaceSection.interviewRecs.rawValue),
            TaskItem(title: "Choose and brief one academic recommender and one legal recommender.", section: WorkspaceSection.interviewRecs.rawValue)
        ]

        modelContext.insert(demoPrompt)
        modelContext.insert(demoReview)
        demoTasks.forEach { modelContext.insert($0) }

        save()
    }

    private func seedDefaultSchools() {
        let defaults = [
            SchoolEntry(name: "Cleveland State University", program: "Online JD / part-time", format: "online", region: "ohio", notes: "Strong fit for working-professional flexibility and Ohio practice."),
            SchoolEntry(name: "Capital University Law School", program: "JD / part-time", format: "inperson", region: "ohio", notes: "Columbus access, local network value, evening compatibility."),
            SchoolEntry(name: "University of Dayton School of Law", program: "Hybrid JD / part-time", format: "hybrid", region: "ohio", notes: "Hybrid flexibility and regional portability.")
        ]
        defaults.forEach { modelContext.insert($0) }
        schools = defaults
    }

    private func shouldInstallDemoWorkspace() -> Bool {
        let hasStatement = !dossier.personalStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return !hasStatement && schools.isEmpty && prompts.isEmpty && reviews.isEmpty && tasks.isEmpty
    }

    private func makeSnapshot() -> WorkspaceBackupSnapshot {
        WorkspaceBackupSnapshot(
            version: "1.0",
            exportedAt: .now,
            profile: .init(
                highestLSAT: profile.highestLSAT,
                cumulativeGPA: profile.cumulativeGPA,
                applicationTiming: profile.applicationTiming,
                scholarshipPriority: profile.scholarshipPriority,
                retakeCapacity: profile.retakeCapacity,
                formatPreference: profile.formatPreference,
                regionPriority: profile.regionPriority,
                careerFocus: profile.careerFocus,
                packageReadiness: profile.packageReadiness,
                costSensitivity: profile.costSensitivity,
                applicationMonth: profile.applicationMonth,
                timelinePressure: profile.timelinePressure
            ),
            dossier: .init(
                personalStatement: dossier.personalStatement,
                resumeText: dossier.resumeText,
                transcriptNotes: dossier.transcriptNotes,
                workSummary: dossier.workSummary,
                recommenderPlan: dossier.recommenderPlan,
                schoolNotes: dossier.schoolNotes,
                weakPoints: dossier.weakPoints,
                optionalEssayIdeas: dossier.optionalEssayIdeas
            ),
            schools: schools.map {
                .init(name: $0.name, program: $0.program, format: $0.format, region: $0.region, notes: $0.notes, medianLSAT: $0.medianLSAT, medianGPA: $0.medianGPA)
            },
            prompts: prompts.map {
                .init(section: $0.section, title: $0.title, body: $0.body, createdAt: $0.createdAt)
            },
            reviews: reviews.map {
                .init(section: $0.section, headline: $0.headline, strengthsText: $0.strengthsText, risksText: $0.risksText, fixesText: $0.fixesText, confidence: $0.confidence, sourceType: $0.sourceType, rawText: $0.rawText, createdAt: $0.createdAt)
            },
            tasks: tasks.map {
                .init(title: $0.title, section: $0.section, isComplete: $0.isComplete, createdAt: $0.createdAt)
            }
        )
    }

    private func apply(snapshot: WorkspaceBackupSnapshot) {
        profile.highestLSAT = snapshot.profile.highestLSAT
        profile.cumulativeGPA = snapshot.profile.cumulativeGPA
        profile.applicationTiming = snapshot.profile.applicationTiming
        profile.scholarshipPriority = snapshot.profile.scholarshipPriority
        profile.retakeCapacity = snapshot.profile.retakeCapacity
        profile.formatPreference = snapshot.profile.formatPreference
        profile.regionPriority = snapshot.profile.regionPriority
        profile.careerFocus = snapshot.profile.careerFocus
        profile.packageReadiness = snapshot.profile.packageReadiness
        profile.costSensitivity = snapshot.profile.costSensitivity
        profile.applicationMonth = snapshot.profile.applicationMonth
        profile.timelinePressure = snapshot.profile.timelinePressure

        dossier.personalStatement = snapshot.dossier.personalStatement
        dossier.resumeText = snapshot.dossier.resumeText
        dossier.transcriptNotes = snapshot.dossier.transcriptNotes
        dossier.workSummary = snapshot.dossier.workSummary
        dossier.recommenderPlan = snapshot.dossier.recommenderPlan
        dossier.schoolNotes = snapshot.dossier.schoolNotes
        dossier.weakPoints = snapshot.dossier.weakPoints
        dossier.optionalEssayIdeas = snapshot.dossier.optionalEssayIdeas

        clear(schools)
        clear(prompts)
        clear(reviews)
        clear(tasks)

        snapshot.schools.forEach {
            let item = SchoolEntry(name: $0.name, program: $0.program, format: $0.format, region: $0.region, notes: $0.notes)
            item.medianLSAT = $0.medianLSAT
            item.medianGPA = $0.medianGPA
            modelContext.insert(item)
        }

        snapshot.prompts.forEach {
            let item = GeneratedPrompt(section: $0.section, title: $0.title, body: $0.body)
            item.createdAt = $0.createdAt
            modelContext.insert(item)
        }

        snapshot.reviews.forEach {
            let item = AIReview(section: $0.section, headline: $0.headline, strengthsText: $0.strengthsText, risksText: $0.risksText, fixesText: $0.fixesText, confidence: $0.confidence, sourceType: $0.sourceType, rawText: $0.rawText)
            item.createdAt = $0.createdAt
            modelContext.insert(item)
        }

        snapshot.tasks.forEach {
            let item = TaskItem(title: $0.title, section: $0.section)
            item.isComplete = $0.isComplete
            item.createdAt = $0.createdAt
            modelContext.insert(item)
        }

        save()
    }

    private func clear<T: PersistentModel>(_ items: [T]) {
        items.forEach { modelContext.delete($0) }
    }
}
