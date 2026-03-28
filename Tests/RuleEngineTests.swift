import XCTest
@testable import LawAdmissionsHQ_Mac

final class RuleEngineTests: XCTestCase {
    func testThemeInferencePrefersRightsAndResilienceSignals() {
        let dossier = Dossier()
        dossier.personalStatement = "My rights advocacy work and resilience after hardship shaped my legal goals."
        XCTAssertEqual(RuleEngine.inferTheme(dossier: dossier), "Rights + resilience")
    }

    func testOverlapRiskFlagsHighReuse() {
        let text = "Managed client intake and legal document review for a high-volume practice."
        XCTAssertTrue(RuleEngine.overlapRisk(statement: text, resume: text).lowercased().contains("high overlap"))
    }
}
