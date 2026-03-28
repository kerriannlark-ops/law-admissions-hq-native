import SwiftUI
import SwiftData

@main
struct LawAdmissionsHQApp: App {
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue

    private let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: ApplicantProfile.self,
                SchoolEntry.self,
                Dossier.self,
                GeneratedPrompt.self,
                AIReview.self,
                TaskItem.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootWorkspaceView()
                .appChrome()
                .background(LawTheme.background.ignoresSafeArea())
                .preferredColorScheme(AppearancePreference(rawValue: appearancePreferenceRaw)?.colorScheme)
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

struct RootWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("preferredIconStyle") private var preferredIconStyle = "standard"
    @State private var store: WorkspaceStore?
    @State private var showSettings = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if let store {
                WorkspaceShellView(store: store, showSettings: $showSettings, showOnboarding: $showOnboarding)
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    .sheet(isPresented: $showOnboarding) {
                        OnboardingView(isPresented: $showOnboarding, hasSeenOnboarding: $hasSeenOnboarding)
                    }
                    .task(id: preferredIconStyle) {
                        try? await AppIconService.apply(style: preferredIconStyle)
                    }
            } else {
                ProgressView("Loading Law Admissions HQ…")
                    .task {
                        self.store = WorkspaceStore(modelContext: modelContext)
                        self.showOnboarding = !hasSeenOnboarding
                    }
            }
        }
    }
}

struct WorkspaceShellView: View {
    @Bindable var store: WorkspaceStore
    @Binding var showSettings: Bool
    @Binding var showOnboarding: Bool

    var body: some View {
        NavigationSplitView {
            List(WorkspaceSection.allCases, selection: $store.selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Law Admissions HQ")
            .scrollContentBackground(.hidden)
            .background(LawTheme.sidebar)
        } detail: {
            detailView
                .background(LawTheme.background.ignoresSafeArea())
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            store.seedRecommendedTasksIfNeeded()
                        } label: {
                            Label("Seed Tasks", systemImage: "checklist")
                        }
                        Button {
                            showOnboarding = true
                        } label: {
                            Label("Guide", systemImage: "sparkles.rectangle.stack")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch store.selectedSection {
        case .dashboard:
            DashboardView(store: store)
        case .dossier:
            DossierView(store: store)
        case .essays:
            EssaysView(store: store)
        case .resumeAddendum:
            ResumeAddendumView(store: store)
        case .interviewRecs:
            InterviewRecsView(store: store)
        case .schoolStrategy:
            SchoolStrategyView(store: store)
        case .promptStudio:
            PromptStudioView(store: store)
        case .sourcesMethod:
            SourcesMethodView()
        }
    }
}

struct DashboardView: View {
    @Bindable var store: WorkspaceStore

    var summary: DashboardSummary {
        RuleEngine.makeDashboard(profile: store.profile, dossier: store.dossier, schools: store.schools)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Dashboard", subtitle: "High-level strategy view: competitiveness, retake logic, reader impression, and next actions.")
                profileCard
                schoolBandingCard
                HStack(alignment: .top, spacing: 16) {
                    metricCard("Retake recommendation", value: summary.retakeMode)
                    metricCard("Biggest risk", value: summary.biggestRisk)
                    metricCard("Reader impression", value: summary.readerImpression)
                    metricCard("Highest leverage move", value: summary.leverageMove)
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Retake strategy") {
                        Text(summary.retakeMode).font(LawTheme.cardTitle)
                        bulletList(summary.retakeReasons)
                        callout(summary.retakeScenario, style: .warning)
                    }
                    borderedCard("Strength / weakness matrix") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(summary.matrix) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.label.uppercased()).font(LawTheme.caption).foregroundStyle(LawTheme.secondaryText)
                                    Text(item.value.capitalized).font(LawTheme.cardTitle)
                                    Text(item.note).font(LawTheme.bodySmall).foregroundStyle(LawTheme.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(LawTheme.cardAlt)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Current package strengths") { bulletList(summary.strengths) }
                    borderedCard("Persistent task queue") {
                        if store.tasks.isEmpty {
                            Text("No tasks yet.").foregroundStyle(LawTheme.secondaryText)
                        } else {
                            ForEach(store.tasks) { task in
                                Button {
                                    store.toggleTask(task)
                                } label: {
                                    HStack(alignment: .top) {
                                        Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.title)
                                                .strikethrough(task.isComplete)
                                            Text(task.section.capitalized)
                                                .font(LawTheme.caption)
                                                .foregroundStyle(LawTheme.secondaryText)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onChange(of: store.profile.highestLSAT) { _, _ in store.save() }
    }

    private var profileCard: some View {
        borderedCard("Applicant profile") {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    formField("Highest LSAT") { Stepper(value: $store.profile.highestLSAT, in: 120...180) { Text("\(store.profile.highestLSAT)") } }
                    formField("Cumulative GPA") { TextField("GPA", value: $store.profile.cumulativeGPA, format: .number.precision(.fractionLength(2))).textFieldStyle(.roundedBorder) }
                    formField("Timing") { Picker("", selection: $store.profile.applicationTiming) { Text("Early").tag("early"); Text("Mid").tag("mid"); Text("Late").tag("late") }.labelsHidden().pickerStyle(.menu) }
                    formField("Scholarships") { Picker("", selection: $store.profile.scholarshipPriority) { Text("High").tag("high"); Text("Medium").tag("medium"); Text("Low").tag("low") }.labelsHidden().pickerStyle(.menu) }
                }
                GridRow {
                    formField("Retake capacity") { Picker("", selection: $store.profile.retakeCapacity) { Text("High").tag("high"); Text("Medium").tag("medium"); Text("Low").tag("low") }.labelsHidden().pickerStyle(.menu) }
                    formField("Format") { Picker("", selection: $store.profile.formatPreference) { Text("Online").tag("online"); Text("Hybrid").tag("hybrid"); Text("In-person").tag("inperson"); Text("Flexible").tag("flex") }.labelsHidden().pickerStyle(.menu) }
                    formField("Region") { Picker("", selection: $store.profile.regionPriority) { Text("Ohio").tag("ohio"); Text("Midwest").tag("midwest"); Text("Open").tag("open") }.labelsHidden().pickerStyle(.menu) }
                    formField("Career focus") { Picker("", selection: $store.profile.careerFocus) { Text("Public interest").tag("public-interest"); Text("General practice").tag("general-practice"); Text("Business").tag("business"); Text("Undecided").tag("undecided") }.labelsHidden().pickerStyle(.menu) }
                }
                GridRow {
                    formField("Readiness") { Picker("", selection: $store.profile.packageReadiness) { Text("Strong").tag("strong"); Text("Mixed").tag("mixed"); Text("Early").tag("early") }.labelsHidden().pickerStyle(.menu) }
                    formField("Cost sensitivity") { Picker("", selection: $store.profile.costSensitivity) { Text("High").tag("high"); Text("Medium").tag("medium"); Text("Low").tag("low") }.labelsHidden().pickerStyle(.menu) }
                    formField("Target month") { TextField("Month", text: $store.profile.applicationMonth).textFieldStyle(.roundedBorder) }
                    formField("Time pressure") { Picker("", selection: $store.profile.timelinePressure) { Text("Manageable").tag("manageable"); Text("Tight").tag("tight"); Text("Very tight").tag("very-tight") }.labelsHidden().pickerStyle(.menu) }
                }
            }
        }
    }

    private var schoolBandingCard: some View {
        borderedCard("School banding") {
            ForEach(Array(store.schools.enumerated()), id: \.element.id) { index, school in
                let assessment = RuleEngine.assessSchool(profile: store.profile, school: school)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(school.name).font(LawTheme.cardTitle)
                            Text(school.program).foregroundStyle(LawTheme.secondaryText)
                        }
                        Spacer()
                        Text(assessment.band)
                            .font(LawTheme.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(bandColor(assessment.band))
                            .clipShape(Capsule())
                    }
                    Text(school.notes)
                    HStack {
                        TextField("Median LSAT", value: binding(for: school, keyPath: \SchoolEntry.medianLSAT), format: .number)
                            .textFieldStyle(.roundedBorder)
                        TextField("Median GPA", value: binding(for: school, keyPath: \SchoolEntry.medianGPA), format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
                    }
                    Text(assessment.reason).font(LawTheme.bodySmall).foregroundStyle(LawTheme.secondaryText)
                    Divider()
                }
            }
        }
    }

    private func binding<T>(for school: SchoolEntry, keyPath: ReferenceWritableKeyPath<SchoolEntry, T>) -> Binding<T> {
        Binding(get: { school[keyPath: keyPath] }, set: { school[keyPath: keyPath] = $0; store.save() })
    }
}

struct DossierView: View {
    @Bindable var store: WorkspaceStore
    var summary: DossierSummary { RuleEngine.makeDossierSummary(profile: store.profile, dossier: store.dossier) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Dossier Workspace", subtitle: "Paste your materials once. Every other section uses these fields.")
                borderedCard("Core dossier inputs") {
                    VStack(spacing: 12) {
                        textEditorField("Personal statement draft", text: $store.dossier.personalStatement, minHeight: 180)
                        textEditorField("Resume / bullets", text: $store.dossier.resumeText, minHeight: 180)
                        textEditorField("Transcript / chronology notes", text: $store.dossier.transcriptNotes, minHeight: 100)
                        textEditorField("Work experience summary", text: $store.dossier.workSummary, minHeight: 100)
                        textEditorField("Recommender plan", text: $store.dossier.recommenderPlan, minHeight: 90)
                        textEditorField("School-specific notes", text: $store.dossier.schoolNotes, minHeight: 90)
                        textEditorField("Weak points / concerns", text: $store.dossier.weakPoints, minHeight: 90)
                        textEditorField("Optional essay ideas", text: $store.dossier.optionalEssayIdeas, minHeight: 90)
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Narrative summary") {
                        Text(summary.theme).font(LawTheme.cardTitle)
                        callout("Theme sentence: My file is ultimately about \(summary.theme.lowercased()), and the strongest version of this application will prove that through academic, legal, and institutional experiences rather than abstract claims alone.", style: .success)
                        bulletList(summary.evidenceBank.isEmpty ? ["Add statement, resume, or work details to generate an evidence bank."] : summary.evidenceBank)
                    }
                    borderedCard("Cross-check flags") {
                        bulletList([
                            summary.overlapRisk,
                            summary.chronologyFlag,
                            summary.whyLawFlag,
                            summary.tailoringNote
                        ])
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Narrative consistency check") { bulletList(summary.consistency) }
                    borderedCard("Fix this next") { bulletList(summary.fixes) }
                }
                AIReviewPane(scope: .dossier, store: store)
            }
            .padding()
        }
        .onDisappear { store.save() }
    }
}

struct EssaysView: View {
    @Bindable var store: WorkspaceStore
    var summary: EssaySummary { RuleEngine.makeEssaySummary(profile: store.profile, dossier: store.dossier) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Essays", subtitle: "Theme-first statement strategy, evidence prompts, and school tailoring.")
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Theme + evidence builder") {
                        codeBox(summary.themeFormula)
                        codeBox(summary.evidenceSentence)
                        codeBox(summary.significanceSentence)
                        Button("Save essay prompt") {
                            let prompt = PromptFactory.makeSectionPrompt(scope: .statement, profile: store.profile, dossier: store.dossier, schools: store.schools, promptMode: store.promptMode, targetSchool: store.targetSchool, customNotes: store.customNotes)
                            store.savePrompt(title: "Essay Revision Prompt", body: prompt, section: .essays)
                        }
                    }
                    borderedCard("Statement quality checks") {
                        bulletList(summary.checks)
                        callout(summary.cutToChase, style: .warning)
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Optional essay brainstorm") { bulletList(summary.optionalEssayIdeas) }
                    borderedCard("School-specific tailoring") {
                        bulletList(summary.schoolTailoring)
                        codeBox(summary.whyProgramBuilder)
                    }
                }
                borderedCard("Voice / authenticity reminders") {
                    bulletList([
                        "Prefer concrete stories over abstract virtue claims.",
                        "Use a conversational, controlled tone instead of academic inflation.",
                        "Do not repeat your resume in paragraph form.",
                        "Close paragraphs by stating significance, not just facts."
                    ])
                }
                AIReviewPane(scope: .statement, store: store)
            }
            .padding()
        }
    }
}

struct ResumeAddendumView: View {
    @Bindable var store: WorkspaceStore
    var summary: ResumeSummary { RuleEngine.makeResumeSummary(profile: store.profile, dossier: store.dossier) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Resume + Addendum", subtitle: "Check strength, overlap, and whether an addendum is actually warranted.")
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Resume strength scanner") { bulletList(summary.strengths) }
                    borderedCard("Redundancy / overlap scan") { bulletList(summary.redundancy) }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Addendum decision") {
                        Text(summary.addendumDecision).font(LawTheme.cardTitle)
                        bulletList(summary.addendumReasons)
                        callout(summary.addendumFormula, style: .warning)
                    }
                    borderedCard("Weakness explanation planner") { bulletList(summary.weaknessPlanner) }
                }
                AIReviewPane(scope: .resumeAddendum, store: store)
            }
            .padding()
        }
    }
}

struct InterviewRecsView: View {
    @Bindable var store: WorkspaceStore
    var summary: InterviewSummary { RuleEngine.makeInterviewSummary(profile: store.profile, dossier: store.dossier) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Interview + Recs", subtitle: "Prepare for file questions, why-law framing, and recommender management.")
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Interview question bank") { bulletList(summary.questions) }
                    borderedCard("Answer builders") {
                        codeBox(summary.whyLawAnswer)
                        codeBox(summary.lsatAnswer)
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Recommender matrix") { bulletList(summary.recommenderMatrix) }
                    borderedCard("Briefing checklist") { callout(summary.briefingChecklist, style: .success) }
                }
                AIReviewPane(scope: .interview, store: store)
            }
            .padding()
        }
    }
}

struct SchoolStrategyView: View {
    @Bindable var store: WorkspaceStore
    var summary: SchoolStrategySummary { RuleEngine.makeSchoolStrategySummary(profile: store.profile, dossier: store.dossier, schools: store.schools) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("School Strategy", subtitle: "Convert school choice into a disciplined fit + cost + timing system.")
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("School-fit matrix") { bulletList(summary.fitList) }
                    borderedCard("Application timeline") { bulletList(summary.timeline) }
                }
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Scholarship / cost planning") {
                        bulletList(summary.costList)
                        codeBox(summary.schoolChoiceBox)
                    }
                    borderedCard("Why this program builder") { codeBox(summary.programBuilder) }
                }
                AIReviewPane(scope: .schoolStrategy, store: store)
            }
            .padding()
        }
    }
}

struct PromptStudioView: View {
    @Bindable var store: WorkspaceStore
    @State private var generatedPrompt: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Prompt Studio", subtitle: "Generate copy-ready prompts using your real dossier, risks, strengths, and target schools.")
                borderedCard("Prompt builder") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Prompt mode", selection: $store.promptMode) {
                            ForEach(PromptMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        TextField("Target school / program", text: $store.targetSchool)
                            .textFieldStyle(.roundedBorder)
                        textEditorField("Extra notes", text: $store.customNotes, minHeight: 110)
                        HStack {
                            Button("Build prompt") {
                                generatedPrompt = PromptFactory.makeSectionPrompt(scope: promptScope(for: store.promptMode), profile: store.profile, dossier: store.dossier, schools: store.schools, promptMode: store.promptMode, targetSchool: store.targetSchool, customNotes: store.customNotes)
                            }
                            Button("Save prompt") {
                                let prompt = generatedPrompt.isEmpty ? PromptFactory.makeSectionPrompt(scope: promptScope(for: store.promptMode), profile: store.profile, dossier: store.dossier, schools: store.schools, promptMode: store.promptMode, targetSchool: store.targetSchool, customNotes: store.customNotes) : generatedPrompt
                                generatedPrompt = prompt
                                store.savePrompt(title: store.promptMode.rawValue, body: prompt, section: .promptStudio)
                            }
                            Button("Copy") {
                                ClipboardService.copy(generatedPrompt)
                            }
                            if !generatedPrompt.isEmpty {
                                ShareLink(item: generatedPrompt)
                            }
                        }
                    }
                }
                borderedCard("Generated prompt") {
                    ScrollView {
                        Text(generatedPrompt.isEmpty ? "Build a prompt to see output here." : generatedPrompt)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 220)
                }
                borderedCard("Saved prompts") {
                    if store.prompts.isEmpty {
                        Text("No saved prompts yet.").foregroundStyle(LawTheme.secondaryText)
                    } else {
                        ForEach(store.prompts) { prompt in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(prompt.title).font(LawTheme.cardTitle)
                                    Spacer()
                                    Text(prompt.section.capitalized).font(LawTheme.caption).foregroundStyle(LawTheme.secondaryText)
                                }
                                Text(prompt.body)
                                    .font(LawTheme.bodySmall)
                                    .foregroundStyle(LawTheme.secondaryText)
                                    .lineLimit(5)
                                HStack {
                                    Button("Load") { generatedPrompt = prompt.body }
                                    Button("Copy") { ClipboardService.copy(prompt.body) }
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if generatedPrompt.isEmpty {
                generatedPrompt = PromptFactory.makeSectionPrompt(scope: promptScope(for: store.promptMode), profile: store.profile, dossier: store.dossier, schools: store.schools, promptMode: store.promptMode, targetSchool: store.targetSchool, customNotes: store.customNotes)
            }
        }
    }

    private func promptScope(for mode: PromptMode) -> AIReviewScope {
        switch mode {
        case .fullReview: return .dossier
        case .statement: return .statement
        case .resumeAddendum: return .resumeAddendum
        case .interview: return .interview
        case .schoolStrategy: return .schoolStrategy
        }
    }
}

struct SourcesMethodView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Sources + Method", subtitle: "Current admissions decisions should rely on official sources. Library-derived strategy is clearly separated.")
                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Official / current verification") {
                        VStack(alignment: .leading, spacing: 8) {
                            Link("LSAC — Applying to Law School", destination: URL(string: "https://www.lsac.org/applying-law-school")!)
                            Link("LSAC — LSAT Argumentative Writing", destination: URL(string: "https://www.lsac.org/lsat/about/lsat-argumentative-writing")!)
                            Link("Cleveland State Law Admissions", destination: URL(string: "https://www.law.csuohio.edu/admission")!)
                            Link("Capital Law Admissions", destination: URL(string: "https://www.law.capital.edu/admissions/")!)
                            Link("University of Dayton Law Admissions", destination: URL(string: "https://udayton.edu/law/admissions/index.php")!)
                        }
                        callout("Use official pages for current deadlines, requirements, optional essays, medians, scholarships, and live application instructions.", style: .warning)
                    }
                    borderedCard("Library-derived guidance used here") {
                        bulletList([
                            "Anna Ivey — admissions-reader perspective, essays, resume, addendum, interview, and school selection.",
                            "Paul Bodine — theme-first writing, evidence sentences, brainstorming, and significance-driven paragraphs.",
                            "Ann Levine — strengths vs weaknesses, application timeline, optional essays, scholarships, and choosing a school.",
                            "How to Write a Law School Personal Statement — authentic voice, common theme, and story-based proof.",
                            "So You Want to Be a Lawyer — pre-1L readiness and profession-facing preparation context."
                        ])
                        callout("These books are used for structure, coaching, and workflow design — not for current school-policy claims.", style: .success)
                    }
                }
                borderedCard("Method") {
                    bulletList([
                        "The app stores profile, dossier, prompts, reviews, and tasks in SwiftData.",
                        "If iCloud / CloudKit is enabled in the app’s capabilities, SwiftData can sync across your Apple devices.",
                        "The AI layer uses the OpenAI Responses API with streaming text support.",
                        "Recommendations are heuristic and transparent, not admissions guarantees.",
                        "Empty fields should produce verify / clarify guidance rather than fake certainty."
                    ])
                }
            }
            .padding()
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @AppStorage("preferredIconStyle") private var preferredIconStyle = "standard"
    @State private var apiKey: String = KeychainService.loadAPIKey()
    @State private var status: String = ""
    @State private var backupJSON: String = ""
    @State private var restoreJSON: String = ""
    @State private var backupStatus: String = ""
    @State private var iconStatus: String = ""
    @State private var store: WorkspaceStore?

    private var appearanceSelection: Binding<AppearancePreference> {
        Binding(
            get: { AppearancePreference(rawValue: appearancePreferenceRaw) ?? .system },
            set: { appearancePreferenceRaw = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Settings + Preview", subtitle: "Control AI access, dark mode, backup / restore, typography, palette, and icon direction before final Xcode packaging.")

                borderedCard("OpenAI") {
                    SecureField("API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Save API Key") {
                            do {
                                try KeychainService.saveAPIKey(apiKey)
                                status = "API key saved to Keychain."
                            } catch {
                                status = error.localizedDescription
                            }
                        }
                        Button("Reload") {
                            apiKey = KeychainService.loadAPIKey()
                        }
                    }
                    if !status.isEmpty {
                        Text(status).font(LawTheme.bodySmall).foregroundStyle(LawTheme.secondaryText)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Appearance") {
                        Picker("Theme", selection: appearanceSelection) {
                            ForEach(AppearancePreference.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        callout("Light mode uses parchment + muted blue for focus. Dark mode uses low-glare ink surfaces with warm serif contrast for longer sessions.", style: .success)
                    }

                    borderedCard("Typography preview") {
                        Text("Times New Roman is now the default UI voice for the app.")
                            .font(LawTheme.body)
                        Text("Law Admissions HQ")
                            .font(LawTheme.title)
                        Text("A calmer serif hierarchy makes reading and editing feel more like a polished admissions workspace than a generic productivity app.")
                            .font(LawTheme.body)
                            .foregroundStyle(LawTheme.secondaryText)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    borderedCard("Color palette") {
                        ThemePalettePreview()
                    }

                    borderedCard("Icon gallery") {
                        IconGallery(preferredIconStyle: $preferredIconStyle, status: $iconStatus)
                        if !iconStatus.isEmpty {
                            Text(iconStatus)
                                .font(LawTheme.bodySmall)
                                .foregroundStyle(LawTheme.secondaryText)
                        }
                        callout("The standard icon is the default build icon. A premium alternate icon asset is now included for final packaging / alternate-icon support.", style: .warning)
                    }
                }

                borderedCard("Backup / restore + demo workspace") {
                    if let store {
                        HStack {
                            Button("Build Backup JSON") {
                                do {
                                    backupJSON = try store.exportBackupJSON()
                                    backupStatus = "Backup generated. Copy, share, or save it before making major changes."
                                } catch {
                                    backupStatus = error.localizedDescription
                                }
                            }
                            Button("Copy Backup") {
                                ClipboardService.copy(backupJSON)
                                backupStatus = backupJSON.isEmpty ? "Build a backup first." : "Backup copied to clipboard."
                            }
                            if !backupJSON.isEmpty {
                                ShareLink(item: backupJSON)
                            }
                            Button("Reload Demo Workspace") {
                                store.seedDemoWorkspace(force: true)
                                backupStatus = "Demo workspace reloaded."
                            }
                        }

                        if !backupStatus.isEmpty {
                            Text(backupStatus)
                                .font(LawTheme.bodySmall)
                                .foregroundStyle(LawTheme.secondaryText)
                        }

                        if !backupJSON.isEmpty {
                            ScrollView {
                                Text(backupJSON)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 180)
                            .padding(10)
                            .background(LawTheme.cardAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        textEditorField("Restore from backup JSON", text: $restoreJSON, minHeight: 140)
                        Button("Restore Backup") {
                            do {
                                try store.importBackupJSON(restoreJSON)
                                backupStatus = "Backup restored successfully."
                            } catch {
                                backupStatus = error.localizedDescription
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        ProgressView("Loading workspace controls…")
                    }
                }

                borderedCard("Sync + final build notes") {
                    bulletList([
                        "This scaffold is iCloud-ready through the CloudKit entitlements file.",
                        "Final CloudKit capability toggles still need to be enabled in full Xcode.",
                        "The premium icon assets are included now; runtime alternate-icon switching is partially wired and ready for final packaging.",
                        "The app remains fully usable without AI if no API key is configured."
                    ])
                }
            }
            .padding()
        }
        .background(LawTheme.background)
        .task {
            if store == nil {
                store = WorkspaceStore(modelContext: modelContext)
            }
        }
    }
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Binding var hasSeenOnboarding: Bool
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @AppStorage("preferredIconStyle") private var preferredIconStyle = "standard"
    @State private var store: WorkspaceStore?
    @State private var onboardingStatus: String = ""

    private var appearanceSelection: Binding<AppearancePreference> {
        Binding(
            get: { AppearancePreference(rawValue: appearancePreferenceRaw) ?? .system },
            set: { appearancePreferenceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("Welcome to Law Admissions HQ", subtitle: "START HERE: choose your reading mode, confirm your workspace style, and then move straight into the dashboard and dossier.")

                    borderedCard("Quick start") {
                        bulletList([
                            "Paste your statement, resume, and transcript notes into Dossier first.",
                            "Use Dashboard next to see retake logic, school banding, and your highest-leverage move.",
                            "Use Essays and Resume + Addendum only after the dossier is loaded with real text.",
                            "Treat official school pages as the authority for current deadlines, essays, and medians."
                        ])
                    }

                    HStack(alignment: .top, spacing: 16) {
                        borderedCard("Choose your appearance") {
                            Picker("Theme", selection: appearanceSelection) {
                                ForEach(AppearancePreference.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            ThemePalettePreview(compact: true)
                        }

                        borderedCard("Choose your icon direction") {
                            IconGallery(preferredIconStyle: $preferredIconStyle, compact: true, status: $onboardingStatus)
                        }
                    }

                    borderedCard("Demo workspace") {
                        Text("A sample law-admissions workspace is seeded automatically on first run if the app starts empty.")
                            .font(LawTheme.body)
                        if let store {
                            Button("Reload Demo Workspace") {
                                store.seedDemoWorkspace(force: true)
                                onboardingStatus = "Demo workspace loaded."
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        if !onboardingStatus.isEmpty {
                            Text(onboardingStatus)
                                .font(LawTheme.bodySmall)
                                .foregroundStyle(LawTheme.secondaryText)
                        }
                    }

                    borderedCard("What this app is built to do") {
                        bulletList([
                            "Keep your law admissions materials in one native workspace across Mac and iPad.",
                            "Give you rule-based strategy even when AI is off.",
                            "Layer AI review on top of a disciplined, source-aware admissions workflow.",
                            "Reduce clutter and decision fatigue with an ADHD-friendly visual system."
                        ])
                    }
                }
                .padding()
            }
            .background(LawTheme.background)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Enter App") {
                        hasSeenOnboarding = true
                        isPresented = false
                    }
                }
            }
        }
        .task {
            if store == nil {
                store = WorkspaceStore(modelContext: modelContext)
            }
        }
    }
}

struct AIReviewPane: View {
    let scope: AIReviewScope
    @Bindable var store: WorkspaceStore
    @StateObject private var service = OpenAIResponsesService()
    @State private var streamedText: String = ""
    @State private var isRunning = false
    @State private var errorMessage = ""

    var body: some View {
        borderedCard("AI analysis") {
            HStack {
                Button(isRunning ? "Analyzing…" : "Analyze with AI") {
                    Task { await runAnalysis() }
                }
                .disabled(isRunning)
                if !streamedText.isEmpty {
                    Button("Copy") { ClipboardService.copy(streamedText) }
                }
            }

            if !errorMessage.isEmpty {
                callout(errorMessage, style: .warning)
            } else {
                callout("If AI is unavailable, keep working with the rule-based dashboard, dossier checks, and revision prompts. This section is designed to degrade gracefully.", style: .success)
            }

            if let latest = store.latestReview(for: scope) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest saved review").font(LawTheme.cardTitle)
                    Text(latest.rawText)
                        .textSelection(.enabled)
                }
                .padding(.top, 10)
            }

            if !streamedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live response").font(LawTheme.cardTitle)
                    Text(streamedText)
                        .textSelection(.enabled)
                }
                .padding(.top, 10)
            }
        }
    }

    private func runAnalysis() async {
        isRunning = true
        errorMessage = ""
        streamedText = ""
        let prompt = PromptFactory.makeSectionPrompt(scope: scope, profile: store.profile, dossier: store.dossier, schools: store.schools, promptMode: store.promptMode, targetSchool: store.targetSchool, customNotes: store.customNotes)
        do {
            for try await chunk in service.streamReview(prompt: prompt) {
                streamedText += chunk
            }
            let payload = service.makeStructuredPayload(scope: scope, rawText: streamedText)
            store.saveAIReview(scope: scope, payload: payload)
        } catch {
            errorMessage = AIServiceFriendlyError.message(for: error, scope: scope)
        }
        isRunning = false
    }
}

// MARK: Shared UI helpers

func sectionHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title).font(LawTheme.title)
        Text(subtitle).font(LawTheme.bodySmall).foregroundStyle(LawTheme.secondaryText)
    }
}

func borderedCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title).font(LawTheme.cardTitle)
        content()
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(LawTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(LawTheme.neutral.opacity(0.55), lineWidth: 1.1))
}

func metricCard(_ title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title.uppercased()).font(LawTheme.caption).foregroundStyle(LawTheme.secondaryText)
        Text(value).font(LawTheme.metric)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(LawTheme.cardAlt)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}

func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label).font(LawTheme.caption).foregroundStyle(LawTheme.secondaryText)
        content()
    }
}

func textEditorField(_ title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(LawTheme.cardTitle)
        TextEditor(text: text)
            .frame(minHeight: minHeight)
            .padding(8)
            .background(LawTheme.cardAlt)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

func bulletList(_ items: [String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(items, id: \.self) { item in
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill").font(.system(size: 7)).foregroundStyle(LawTheme.accent).padding(.top, 7)
                Text(item)
            }
        }
    }
}

enum CalloutStyle {
    case warning, success
    var color: Color { self == .warning ? LawTheme.warning : LawTheme.success }
}

func callout(_ text: String, style: CalloutStyle) -> some View {
    Text(text)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.color.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(style.color.opacity(0.4)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

func codeBox(_ text: String) -> some View {
    Text(text)
        .font(LawTheme.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(LawTheme.cardAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

func bandColor(_ band: String) -> Color {
    switch band {
    case "Safer": return LawTheme.success.opacity(0.18)
    case "Realistic": return LawTheme.accentSoft
    case "Reach": return LawTheme.warning.opacity(0.20)
    default: return LawTheme.neutral.opacity(0.22)
    }
}

struct ThemePalettePreview: View {
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            paletteRow([
                ("Background", LawTheme.background),
                ("Card", LawTheme.card),
                ("Card Alt", LawTheme.cardAlt)
            ])
            paletteRow([
                ("Accent", LawTheme.accent),
                ("Success", LawTheme.success),
                ("Warning", LawTheme.warning)
            ])
            if !compact {
                Text("Designed for lower glare, calmer contrast, and cleaner reading flow on Mac and iPad.")
                    .font(LawTheme.bodySmall)
                    .foregroundStyle(LawTheme.secondaryText)
            }
        }
    }

    @ViewBuilder
    private func paletteRow(_ items: [(String, Color)]) -> some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.1)
                        .frame(height: compact ? 48 : 58)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LawTheme.neutral.opacity(0.4), lineWidth: 1))
                    Text(item.0)
                        .font(compact ? LawTheme.caption : LawTheme.bodySmall)
                        .foregroundStyle(LawTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct IconGallery: View {
    @Binding var preferredIconStyle: String
    var compact: Bool = false
    var status: Binding<String>? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            iconCard(title: "Standard", imageName: "IconStandard", value: "standard", note: "Document + check")
            iconCard(title: "Premium", imageName: "IconPremium", value: "premium", note: "Serif monogram + gold")
        }
    }

    @ViewBuilder
    private func iconCard(title: String, imageName: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(imageName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: compact ? 120 : 156)
                .clipShape(RoundedRectangle(cornerRadius: compact ? 20 : 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: compact ? 20 : 28).stroke(LawTheme.neutral.opacity(0.45), lineWidth: 1))
            Text(title)
                .font(LawTheme.cardTitle)
            Text(note)
                .font(LawTheme.bodySmall)
                .foregroundStyle(LawTheme.secondaryText)
            Button(preferredIconStyle == value ? "Selected" : "Prefer this style") {
                Task {
                    preferredIconStyle = value
                    do {
                        try await AppIconService.apply(style: value)
                        status?.wrappedValue = value == "premium" ? "Premium icon preference applied." : "Standard icon preference applied."
                    } catch {
                        status?.wrappedValue = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(preferredIconStyle == value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
