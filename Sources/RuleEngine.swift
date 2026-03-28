import Foundation

struct SchoolAssessment: Identifiable {
    let id = UUID()
    let schoolName: String
    let band: String
    let reason: String
    let confidence: String
    let verificationNeeded: Bool
}

struct DashboardSummary {
    let retakeMode: String
    let retakeReasons: [String]
    let retakeScenario: String
    let biggestRisk: String
    let readerImpression: String
    let leverageMove: String
    let strengths: [String]
    let actions: [String]
    let schoolAssessments: [SchoolAssessment]
    let matrix: [StrengthMatrixItem]
}

struct StrengthMatrixItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let note: String
}

struct DossierSummary {
    let theme: String
    let evidenceBank: [String]
    let overlapRisk: String
    let chronologyFlag: String
    let whyLawFlag: String
    let tailoringNote: String
    let consistency: [String]
    let fixes: [String]
}

struct EssaySummary {
    let themeFormula: String
    let evidenceSentence: String
    let significanceSentence: String
    let checks: [String]
    let cutToChase: String
    let optionalEssayIdeas: [String]
    let schoolTailoring: [String]
    let whyProgramBuilder: String
}

struct ResumeSummary {
    let strengths: [String]
    let redundancy: [String]
    let addendumDecision: String
    let addendumReasons: [String]
    let addendumFormula: String
    let weaknessPlanner: [String]
}

struct InterviewSummary {
    let questions: [String]
    let whyLawAnswer: String
    let lsatAnswer: String
    let recommenderMatrix: [String]
    let briefingChecklist: String
}

struct SchoolStrategySummary {
    let fitList: [String]
    let timeline: [String]
    let costList: [String]
    let schoolChoiceBox: String
    let programBuilder: String
}

enum RuleEngine {
    private static let clichéPhrases = [
        "make a difference", "give back", "passion for law", "always wanted to be a lawyer", "help people", "change the world", "from a young age"
    ]

    private static let weaknessKeywords = [
        "gap", "withdraw", "probation", "disciplinary", "leave", "low grade", "transfer", "illness", "family emergency", "financial hardship", "score"
    ]

    private static let legalKeywords = [
        "law", "legal", "rights", "advocacy", "attorney", "court", "case", "justice", "compliance", "document", "client", "policy"
    ]

    private static let actionVerbs = [
        "led", "managed", "organized", "drafted", "supported", "coordinated", "researched", "assisted", "reviewed", "prepared", "oversaw", "trained", "built"
    ]

    static func makeDashboard(profile: ApplicantProfile, dossier: Dossier, schools: [SchoolEntry]) -> DashboardSummary {
        let dossierSummary = makeDossierSummary(profile: profile, dossier: dossier)
        let retake = retakeMode(profile: profile)
        let schoolAssessments = schools.map { assessSchool(profile: profile, school: $0) }
        let matrix = [
            StrengthMatrixItem(label: "Numbers", value: profile.highestLSAT >= 153 ? "stronger" : profile.highestLSAT >= 150 ? "mixed" : "constraint", note: "LSAT \(profile.highestLSAT) / GPA \(String(format: "%.2f", profile.cumulativeGPA))"),
            StrengthMatrixItem(label: "Academics", value: profile.cumulativeGPA >= 3.5 ? "strong" : "mixed", note: "Transcript framing + GPA signal"),
            StrengthMatrixItem(label: "Professional readiness", value: countHits(text: dossier.workSummary + " " + dossier.resumeText, terms: legalKeywords) >= 3 ? "strong" : "mixed", note: "Legal and client-facing work signals"),
            StrengthMatrixItem(label: "Writing / narrative", value: dossierSummary.whyLawFlag.contains("Present") ? "workable" : "needs work", note: "Theme, specificity, and why-law clarity"),
            StrengthMatrixItem(label: "School fit", value: profile.regionPriority == "ohio" ? "focused" : "broader", note: "Format, region, and life-fit discipline")
        ]

        let strengths = [
            "Academic performance and honors provide real counterweight to the LSAT.",
            "Legal work experience gives the file professional substance.",
            "Theme signal: \(dossierSummary.theme).",
            "Ohio / part-time / hybrid / online discipline improves strategic clarity."
        ]

        var actions = dossierSummary.fixes.prefix(3).map { $0 }
        if actions.isEmpty {
            actions = ["Refine school-specific tailoring and interview answers next."]
        }
        if retake.mode == "Delay and retake" {
            actions.append("Decide whether the expected score gain justifies delaying applications for better scholarship leverage.")
        } else {
            actions.append("Keep building a realistic school list instead of widening the list without better fit data.")
        }

        return DashboardSummary(
            retakeMode: retake.mode,
            retakeReasons: retake.reasons,
            retakeScenario: retake.scenario,
            biggestRisk: dossierSummary.fixes.first ?? "Statement precision needs work because the LSAT is not doing the heavy lifting.",
            readerImpression: dossier.personalStatement.isEmpty ? "Reader will default to numbers and resume until the narrative pieces are pasted and refined." : "Reader sees substance, but statement precision must carry more weight because the LSAT is not doing that work for you.",
            leverageMove: actions.first ?? "Sharpen statement evidence.",
            strengths: strengths,
            actions: actions,
            schoolAssessments: schoolAssessments,
            matrix: matrix
        )
    }

    static func makeDossierSummary(profile: ApplicantProfile, dossier: Dossier) -> DossierSummary {
        let theme = inferTheme(dossier: dossier)
        let evidence = evidenceBank(dossier: dossier)
        let overlap = overlapRisk(statement: dossier.personalStatement, resume: dossier.resumeText)
        let chronology = chronologyFlag(dossier: dossier)
        let whyLaw = whyLawFlag(dossier: dossier)
        let tailoring = schoolTailoringNote(profile: profile, dossier: dossier)

        var consistency = [String]()
        if overlap.lowercased().contains("high") {
            consistency.append("The statement and resume are using too much of the same language.")
        } else {
            consistency.append("The statement can still be differentiated from the resume through more interiority and significance.")
        }

        if chronology.lowercased().contains("potential") {
            consistency.append("Transcript chronology likely needs short factual context somewhere in the file or in an addendum.")
        } else {
            consistency.append("Chronology does not currently look like the single biggest risk if framed cleanly.")
        }

        if whyLaw.lowercased().contains("thin") {
            consistency.append("The file needs a clearer why-law bridge between values, experience, and legal study.")
        } else {
            consistency.append("The dossier contains at least some law-specific motivation language.")
        }

        var fixes = [String]()
        if dossier.personalStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fixes.append("Paste a personal statement so the essay and overlap engines can work fully.")
        }
        if whyLaw.lowercased().contains("thin") {
            fixes.append("Add 1–2 explicit sentences explaining why law is the right vehicle for your goals.")
        }
        if overlap.lowercased().contains("high") {
            fixes.append("Rewrite the statement to explain meaning and growth, not just tasks or accomplishments.")
        }
        if chronology.lowercased().contains("potential") {
            fixes.append("Draft a short factual addendum if the record truly needs context.")
        }
        if genericRisk(statement: dossier.personalStatement) != "Controlled" {
            fixes.append("Replace generic motivation language with concrete institutional or legal experiences.")
        }
        if fixes.isEmpty {
            fixes.append("Refine school-specific tailoring and interview answers next.")
        }

        return DossierSummary(
            theme: theme,
            evidenceBank: evidence,
            overlapRisk: overlap,
            chronologyFlag: chronology,
            whyLawFlag: whyLaw,
            tailoringNote: tailoring,
            consistency: consistency,
            fixes: fixes
        )
    }

    static func makeEssaySummary(profile: ApplicantProfile, dossier: Dossier) -> EssaySummary {
        let dossierSummary = makeDossierSummary(profile: profile, dossier: dossier)
        let statementText = dossier.personalStatement.lowercased()
        let concreteSignals = countHits(text: statementText, terms: actionVerbs + legalKeywords) + statementText.filter { $0.isNumber }.count
        let abstractClaims = countHits(text: statementText, terms: ["hard-working", "leadership", "critical thinking", "passionate", "dedicated", "intelligent"])

        var checks = [String]()
        if dossier.personalStatement.isEmpty {
            checks.append("Paste a statement draft to generate essay-specific feedback.")
        } else {
            checks.append(concreteSignals >= abstractClaims + 2 ? "Concrete detail is present enough to support show, don’t tell." : "Add more concrete scenes, actions, legal moments, or outcomes to reduce abstraction.")
            checks.append(abstractClaims > 1 ? "You may be naming traits directly instead of proving them through events." : "Trait claims do not currently overwhelm the evidence.")
            checks.append(genericRisk(statement: dossier.personalStatement) == "Controlled" ? "Generic motivation language is not dominating the statement." : "Reduce generic motivation phrases and replace them with file-specific reasoning.")
            checks.append(dossierSummary.whyLawFlag.contains("Present") ? "The statement connects values to legal study with some clarity." : "The why-law link needs to be more explicit.")
        }

        return EssaySummary(
            themeFormula: """
            Theme-first statement formula
            \(dossierSummary.theme) → one concrete moment → what it taught you → why it points toward law → why it matters now
            """,
            evidenceSentence: """
            Evidence sentence
            This experience demonstrates \(dossierSummary.theme.lowercased()) because I [specific action], not merely because I claim to value it.
            """,
            significanceSentence: """
            Significance sentence
            What matters about this experience is not only what happened, but that it taught me [lesson] and made law the right next framework for my work.
            """,
            checks: checks,
            cutToChase: "Reader-speed summary: \(dossierSummary.theme) + \(profile.highestLSAT) LSAT means the statement must quickly prove legal readiness through real experiences, not only ideals.",
            optionalEssayIdeas: optionalEssayIdeas(dossier: dossier),
            schoolTailoring: schoolTailoring(profile: profile, dossier: dossier),
            whyProgramBuilder: "I am drawn to this program because its \(profile.formatPreference) structure, regional fit, and mission align with my experience in \(dossierSummary.theme.lowercased()) and my goal of \(profile.careerFocus.replacingOccurrences(of: "-", with: " ")) work."
        )
    }

    static func makeResumeSummary(profile: ApplicantProfile, dossier: Dossier) -> ResumeSummary {
        let text = (dossier.resumeText + " " + dossier.workSummary).lowercased()
        var strengths = [String]()
        if countHits(text: text, terms: actionVerbs) >= 4 { strengths.append("Your resume language shows action and responsibility rather than passive listing.") }
        if countHits(text: text, terms: legalKeywords) >= 3 { strengths.append("Legal vocabulary appears enough to support profession-facing credibility.") }
        if text.contains(where: { $0.isNumber }) { strengths.append("Quantitative or time markers help credibility and specificity.") }
        if text.contains("lead") || text.contains("manage") || text.contains("train") { strengths.append("Leadership or ownership signals appear in the resume/work content.") }
        if strengths.isEmpty { strengths = ["Add more action verbs, responsibility signals, and concrete outcomes to strengthen the resume."] }

        let redundancy = [
            overlapRisk(statement: dossier.personalStatement, resume: dossier.resumeText),
            Set(dossier.resumeText.split(separator: "\n").map(String.init)).count == dossier.resumeText.split(separator: "\n").count ? "Resume bullets do not appear obviously repetitive at a line level." : "Some resume bullets may be repetitive or too similar to one another."
        ]

        let weakText = (dossier.transcriptNotes + " " + dossier.weakPoints).lowercased()
        let addendumDecision: String
        var addendumReasons = [String]()
        if countHits(text: weakText, terms: ["probation", "disciplinary", "withdraw", "leave", "financial hardship", "illness", "family emergency", "gap"]) >= 2 {
            addendumDecision = "Likely needed"
            addendumReasons.append("Your notes suggest there may be a real context issue that benefits from concise explanation.")
        } else if countHits(text: weakText, terms: ["transfer", "gap", "low grade", "score"]) >= 1 {
            addendumDecision = "Optional / context-dependent"
            addendumReasons.append("There may be a point worth clarifying, but it should only be addressed if it truly changes how the file is read.")
        } else {
            addendumDecision = "Probably unnecessary"
            addendumReasons.append("The current notes do not strongly suggest a necessary addendum.")
        }
        if profile.highestLSAT <= 148 {
            addendumReasons.append("A low LSAT by itself usually does not justify an addendum unless there is real explanatory context.")
        }

        return ResumeSummary(
            strengths: strengths,
            redundancy: redundancy,
            addendumDecision: addendumDecision,
            addendumReasons: addendumReasons,
            addendumFormula: "Issue → brief factual context → what changed or stabilized → concise close. Avoid excuse-heavy tone.",
            weaknessPlanner: [
                "Use the statement for meaning, growth, and motivation.",
                "Use the resume for task scope, responsibility, and outcomes.",
                "Use the addendum only for clean factual clarification where silence would confuse the reader."
            ]
        )
    }

    static func makeInterviewSummary(profile: ApplicantProfile, dossier: Dossier) -> InterviewSummary {
        let theme = inferTheme(dossier: dossier).lowercased()
        var questions = [
            "Why law, specifically, instead of another service or policy path?",
            "What has your legal assistant experience shown you about the actual profession?",
            "Why is this program format right for you?",
            "How do you explain your LSAT score in the context of the rest of your file?"
        ]
        if !dossier.schoolNotes.isEmpty { questions.append("Which part of this school’s structure or mission most genuinely fits your path?") }
        if !dossier.transcriptNotes.isEmpty { questions.append("How would you walk me through your academic trajectory in a way that makes sense?") }

        let recommenderText = dossier.recommenderPlan.lowercased()
        var matrix = [String]()
        if recommenderText.contains("professor") || recommenderText.contains("academic") {
            matrix.append("You appear to have at least one academic recommender path, which is helpful for classroom-readiness credibility.")
        } else {
            matrix.append("Try to include at least one academic recommender if possible, especially someone who can speak to writing or analytical skill.")
        }
        if recommenderText.contains("supervisor") || recommenderText.contains("legal") || recommenderText.contains("employer") {
            matrix.append("A legal or professional recommender can validate discipline, discretion, and judgment.")
        } else {
            matrix.append("Add one work recommender who can speak to professionalism, ownership, and reliability.")
        }

        return InterviewSummary(
            questions: questions,
            whyLawAnswer: "My path toward law became concrete through \(theme) experiences that showed me [specific legal problem or institutional pattern], and law now feels like the clearest framework for the kind of work I want to do.",
            lsatAnswer: "My \(profile.highestLSAT) does not reflect the strongest parts of my file, but I take it seriously. What I think is more representative is [academic/work evidence], and I have learned [lesson / improvement / context] from the process.",
            recommenderMatrix: matrix,
            briefingChecklist: "Resume, statement draft, school list, 3 strengths you want emphasized, 2 concrete examples they can mention, and your reason for pursuing law now."
        )
    }

    static func makeSchoolStrategySummary(profile: ApplicantProfile, dossier: Dossier, schools: [SchoolEntry]) -> SchoolStrategySummary {
        let fitList = schools.map { school in
            let assessment = assessSchool(profile: profile, school: school)
            return "\(assessment.schoolName): \(assessment.band). \(assessment.reason)"
        }

        var timeline = [String]()
        timeline.append("Submit core applications by \(profile.applicationMonth) if possible.")
        timeline.append("Verify school-specific optional essays, recommendation counts, and fee policies on official pages.")
        if profile.timelinePressure == "very-tight" || profile.applicationTiming == "late" {
            timeline.append("Under tight timing, prioritize your strongest-fit schools first and do not over-expand the list.")
        } else {
            timeline.append("Use the extra runway to improve tailoring, not just accumulate more schools.")
        }

        var costList = [String]()
        if profile.costSensitivity == "high" {
            costList.append("With high cost sensitivity, scholarship leverage should remain central to your school list decisions.")
        }
        if profile.scholarshipPriority == "high" {
            costList.append("A modest LSAT increase could meaningfully affect scholarship outcomes; keep that in the strategic frame.")
        }
        costList.append("Compare format flexibility and debt burden with the same seriousness as admissions odds.")

        return SchoolStrategySummary(
            fitList: fitList,
            timeline: timeline,
            costList: costList,
            schoolChoiceBox: "Competitiveness + format fit + regional value + cost realism + career alignment = better school choices than prestige alone.",
            programBuilder: "I am interested in this program because its \(profile.formatPreference) structure, \(profile.regionPriority) value, and fit with my \(profile.careerFocus.replacingOccurrences(of: "-", with: " ")) goals make it a realistic and meaningful next step."
        )
    }

    static func assessSchool(profile: ApplicantProfile, school: SchoolEntry) -> SchoolAssessment {
        var score: Double = 0
        var reasons = [String]()
        let verificationNeeded = school.medianLSAT == nil && school.medianGPA == nil

        if let medianLSAT = school.medianLSAT {
            let delta = profile.highestLSAT - medianLSAT
            if delta >= 2 { score += 2; reasons.append("LSAT above entered median") }
            else if delta >= -1 { score += 1; reasons.append("LSAT near entered median") }
            else if delta >= -4 { reasons.append("LSAT below but not totally out of band") }
            else { score -= 2; reasons.append("LSAT meaningfully below entered median") }
        } else {
            reasons.append("official LSAT median not entered")
        }

        if let medianGPA = school.medianGPA {
            let delta = profile.cumulativeGPA - medianGPA
            if delta >= 0.10 { score += 1; reasons.append("GPA above entered median") }
            else if delta >= -0.10 { score += 0.5; reasons.append("GPA near entered median") }
            else { score -= 0.5; reasons.append("GPA below entered median") }
        } else {
            reasons.append("official GPA median not entered")
        }

        if profile.formatPreference == "flex" || profile.formatPreference == school.format || (profile.formatPreference == "hybrid" && ["hybrid", "online"].contains(school.format)) {
            score += 1
            reasons.append("format fit is favorable")
        }
        if profile.regionPriority == "open" || profile.regionPriority == school.region || (profile.regionPriority == "midwest" && school.region != "open") {
            score += 1
            reasons.append("regional fit is favorable")
        }
        if profile.costSensitivity == "high" && profile.scholarshipPriority == "high" {
            score -= 0.25
        }

        let band: String
        if verificationNeeded {
            band = score >= 2 ? "Realistic" : "Needs official data"
        } else {
            band = score >= 3 ? "Safer" : score >= 1.25 ? "Realistic" : "Reach"
        }

        return SchoolAssessment(
            schoolName: school.name,
            band: band,
            reason: reasons.prefix(3).joined(separator: "; ") + ".",
            confidence: verificationNeeded ? "Moderate — missing official medians." : "Stronger — user-entered official medians present.",
            verificationNeeded: verificationNeeded
        )
    }

    static func inferTheme(dossier: Dossier) -> String {
        let text = (dossier.personalStatement + " " + dossier.workSummary + " " + dossier.weakPoints + " " + dossier.schoolNotes).lowercased()
        let themes: [(String, [String])] = [
            ("Rights + resilience", ["rights", "resilience", "advocacy", "justice", "institution"]),
            ("Legal service + professionalism", ["legal", "client", "document", "case", "professional"]),
            ("Leadership + discipline", ["leadership", "build", "business", "manage", "responsibility"]),
            ("Public-interest mission", ["public", "community", "service", "equity", "access"]),
            ("Academic + analytical growth", ["research", "analysis", "writing", "political", "study"])
        ]

        return themes.max(by: { countHits(text: text, terms: $0.1) < countHits(text: text, terms: $1.1) })?.0 ?? "Rights + resilience"
    }

    static func evidenceBank(dossier: Dossier) -> [String] {
        let combined = dossier.personalStatement + " " + dossier.workSummary + " " + dossier.resumeText
        let candidateSentences = combined.replacingOccurrences(of: "\n", with: " ").split(whereSeparator: { ".!?".contains($0) }).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let hits = candidateSentences.filter { sentence in
            sentence.count > 40 && (countHits(text: sentence, terms: legalKeywords) > 0 || countHits(text: sentence, terms: actionVerbs) > 0 || sentence.contains(where: { $0.isNumber }))
        }
        return Array(NSOrderedSet(array: hits).array as? [String] ?? []).prefix(6).map { $0 }
    }

    static func overlapRisk(statement: String, resume: String) -> String {
        let ratio = overlapRatio(statement, resume)
        if statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resume.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Needs both documents — paste both statement and resume text for overlap analysis."
        }
        if ratio > 0.42 { return "High overlap risk — too much shared language suggests the statement may be restating the resume." }
        if ratio > 0.26 { return "Moderate overlap risk — some resume rehash risk exists; make sure the statement adds interiority and significance." }
        return "Controlled overlap — the statement appears meaningfully different from the resume."
    }

    static func chronologyFlag(dossier: Dossier) -> String {
        let text = (dossier.transcriptNotes + " " + dossier.weakPoints).lowercased()
        let hits = countHits(text: text, terms: weaknessKeywords)
        if dossier.transcriptNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Needs input — add transcript notes so chronology can be evaluated."
        }
        if hits >= 2 { return "Potential addendum candidate — your chronology notes suggest there may be issues that need short factual context." }
        if text.contains("magna cum laude") || text.contains("completed") { return "Mostly coherent — the path looks completion-focused, but make sure transfers or changes are explained cleanly." }
        return "Review for clarity — the current notes do not yet make the timeline feel intentional."
    }

    static func whyLawFlag(dossier: Dossier) -> String {
        let text = (dossier.personalStatement + " " + dossier.schoolNotes).lowercased()
        return countHits(text: text, terms: ["law", "legal", "attorney", "lawyer", "rights", "justice"]) >= 2 ?
            "Present — the dossier contains at least some explicit legal motivation language." :
            "Thin — the file risks sounding values-based without explaining why law is the right vehicle."
    }

    static func schoolTailoringNote(profile: ApplicantProfile, dossier: Dossier) -> String {
        schoolTailoring(profile: profile, dossier: dossier).first ?? "Add school-specific notes to generate a stronger tailoring read."
    }

    static func schoolTailoring(profile: ApplicantProfile, dossier: Dossier) -> [String] {
        let notes = dossier.schoolNotes.lowercased()
        var ideas = [String]()
        if notes.contains("online") || profile.formatPreference == "online" { ideas.append("Explicitly tie your working-professional reality to online flexibility and follow-through.") }
        if notes.contains("hybrid") || profile.formatPreference == "hybrid" { ideas.append("Highlight why hybrid structure protects both rigor and practical sustainability.") }
        if profile.regionPriority == "ohio" { ideas.append("Connect Ohio location or network value to your long-term practice goals.") }
        if profile.careerFocus == "public-interest" { ideas.append("Show how mission, clinics, or public-service identity support your legal goals.") }
        if profile.costSensitivity == "high" { ideas.append("Keep cost realism in mind even when writing why-this-school language.") }
        return ideas
    }

    static func optionalEssayIdeas(dossier: Dossier) -> [String] {
        let text = (dossier.optionalEssayIdeas + " " + dossier.weakPoints + " " + dossier.personalStatement).lowercased()
        var ideas = [String]()
        if text.contains("obstacle") || text.contains("resilience") || text.contains("hardship") { ideas.append("Obstacles-overcome essay: emphasize adaptation, discipline, and what changed in your trajectory.") }
        if text.contains("rights") || text.contains("disability") || text.contains("advocacy") { ideas.append("Values/diversity essay: connect lived perspective to legal seriousness, not just identity description.") }
        if text.contains("business") || text.contains("notary") { ideas.append("Professional identity essay: show business-building discipline and client-facing responsibility.") }
        ideas.append("Leadership essay: use a real responsibility example rather than a generic leadership label.")
        return Array(NSOrderedSet(array: ideas).array as? [String] ?? [])
    }

    static func genericRisk(statement: String) -> String {
        let lower = statement.lowercased()
        let count = countHits(text: lower, terms: clichéPhrases)
        if statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "No statement pasted yet" }
        if count >= 3 { return "High generic risk" }
        if count >= 1 { return "Some generic drift" }
        return "Controlled"
    }

    private static func retakeMode(profile: ApplicantProfile) -> (mode: String, reasons: [String], scenario: String) {
        var reasons = [String]()
        var mode = "Apply now + selective retake"
        if profile.highestLSAT <= 148 { reasons.append("147–148 remains the biggest admissions and scholarship constraint.") }
        if profile.scholarshipPriority == "high" { reasons.append("High scholarship priority increases the value of score improvement.") }
        if profile.retakeCapacity == "high" { reasons.append("Your stated study capacity makes a serious retake more plausible.") }
        if profile.timelinePressure == "very-tight" || profile.applicationTiming == "late" { reasons.append("Timing pressure makes full delay more costly.") }
        if profile.retakeCapacity == "low" { reasons.append("Low realistic capacity weakens the case for delaying everything around a retake.") }
        if profile.highestLSAT <= 148 && profile.scholarshipPriority == "high" && profile.retakeCapacity == "high" && profile.applicationTiming != "late" && profile.timelinePressure != "very-tight" {
            mode = "Delay and retake"
        } else if profile.retakeCapacity == "low" {
            mode = "Apply now"
        }
        return (mode, reasons, "147 → 150 = modest but useful gain; 147 → 153 = materially stronger regional competitiveness; 147 → 155+ = much better scholarship leverage and wider school range.")
    }

    private static func countHits(text: String, terms: [String]) -> Int {
        let lower = text.lowercased()
        return terms.reduce(0) { total, term in total + (lower.contains(term) ? 1 : 0) }
    }

    private static func overlapRatio(_ lhs: String, _ rhs: String) -> Double {
        let setA = Set(lhs.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count > 2 })
        let setB = Set(rhs.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count > 2 })
        guard !setA.isEmpty, !setB.isEmpty else { return 0 }
        let shared = setA.intersection(setB).count
        return Double(shared) / Double(max(setA.count, setB.count))
    }
}
