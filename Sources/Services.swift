import Foundation
import Security
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum KeychainService {
    private static let service = "LawAdmissionsHQNative"
    private static let account = "OPENAI_API_KEY"

    static func saveAPIKey(_ apiKey: String) throws {
        let data = Data(apiKey.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    static func loadAPIKey() -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
}

enum ClipboardService {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}


struct AIServiceFriendlyError {
    static func message(for error: Error, scope: AIReviewScope) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "You appear to be offline. AI review could not run for the \(scope.title.lowercased()) section. The app still works in rule-based mode, so continue using the dashboard and revision guidance locally."
            case .timedOut:
                return "The AI request timed out. Try again on a stronger connection, or continue with the built-in rule-based coaching for now."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "The app could not reach the OpenAI service. Check your connection or try again later. Rule-based guidance is still available."
            default:
                return urlError.localizedDescription + " Rule-based guidance is still available while AI is unavailable."
            }
        }

        let nsError = error as NSError
        switch nsError.code {
        case 401:
            return "No valid OpenAI API key is configured. Add or refresh your key in Settings. You can still use the app without AI."
        case 403:
            return "The API key was rejected for this request. Verify your OpenAI account permissions and try again."
        case 429:
            return "OpenAI rate limits were hit. Wait a moment, then retry. Your rule-based admissions guidance is still available."
        default:
            if nsError.domain == "OpenAI" {
                return nsError.localizedDescription + " The section remains usable in non-AI mode."
            }
            return error.localizedDescription + " The section remains usable in non-AI mode."
        }
    }
}

struct AIReviewPayload {
    let headline: String
    let strengthsText: String
    let risksText: String
    let fixesText: String
    let confidence: String
    let sourceType: String
    let rawText: String
}

@MainActor
final class OpenAIResponsesService: ObservableObject {
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func streamReview(prompt: String, model: String = "gpt-5-mini") -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = KeychainService.loadAPIKey()
                    guard !apiKey.isEmpty else {
                        throw NSError(domain: "OpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No API key configured. Add one in Settings."])
                    }

                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

                    let body: [String: Any] = [
                        "model": model,
                        "input": prompt,
                        "stream": true,
                        "store": false
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI request failed with status \(http.statusCode)."] )
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8) else { continue }
                        if let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                            switch event.type {
                            case "response.output_text.delta":
                                if let delta = event.delta { continuation.yield(delta) }
                            case "response.completed":
                                continuation.finish()
                            case "error":
                                let message = event.error?.message ?? "Streaming error"
                                continuation.finish(throwing: NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: message]))
                            default:
                                continue
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func makeStructuredPayload(scope: AIReviewScope, rawText: String) -> AIReviewPayload {
        AIReviewPayload(
            headline: "\(scope.title) review",
            strengthsText: "See raw analysis.",
            risksText: "See raw analysis.",
            fixesText: "See raw analysis.",
            confidence: "AI-generated",
            sourceType: "OpenAI Responses API",
            rawText: rawText
        )
    }
}

private struct StreamEvent: Decodable {
    struct StreamError: Decodable {
        let message: String?
    }

    let type: String
    let delta: String?
    let error: StreamError?
}

enum PromptFactory {
    static func makeSectionPrompt(scope: AIReviewScope, profile: ApplicantProfile, dossier: Dossier, schools: [SchoolEntry], promptMode: PromptMode, targetSchool: String, customNotes: String) -> String {
        let dashboard = RuleEngine.makeDashboard(profile: profile, dossier: dossier, schools: schools)
        let dossierSummary = RuleEngine.makeDossierSummary(profile: profile, dossier: dossier)
        let resume = RuleEngine.makeResumeSummary(profile: profile, dossier: dossier)
        let schoolSummary = RuleEngine.makeSchoolStrategySummary(profile: profile, dossier: dossier, schools: schools)

        let scopeInstruction: String = {
            switch scope {
            case .dossier: return "Review my law school dossier and tell me the strongest theme, biggest inconsistency, and best next revision target."
            case .statement: return "Review my personal statement using a theme-first law admissions lens."
            case .resumeAddendum: return "Review my resume and advise whether an addendum is needed."
            case .interview: return "Help me prepare for law school interviews and explain my file cleanly."
            case .schoolStrategy: return "Help me calibrate my school list, timing, and scholarship strategy."
            }
        }()

        return """
        \(scopeInstruction)

        Applicant profile:
        - Highest LSAT: \(profile.highestLSAT)
        - GPA: \(String(format: "%.2f", profile.cumulativeGPA))
        - Timing: \(profile.applicationTiming)
        - Scholarship priority: \(profile.scholarshipPriority)
        - Retake capacity: \(profile.retakeCapacity)
        - Format preference: \(profile.formatPreference)
        - Region priority: \(profile.regionPriority)
        - Career focus: \(profile.careerFocus)
        - Cost sensitivity: \(profile.costSensitivity)

        Current strategic read:
        - Retake recommendation: \(dashboard.retakeMode)
        - Biggest risk: \(dashboard.biggestRisk)
        - Theme: \(dossierSummary.theme)
        - Why-law read: \(dossierSummary.whyLawFlag)
        - Resume overlap: \(dossierSummary.overlapRisk)
        - Addendum decision: \(resume.addendumDecision)

        Statement:
        \(dossier.personalStatement.isEmpty ? "[not pasted]" : dossier.personalStatement)

        Resume / work:
        \(dossier.resumeText.isEmpty ? "[not pasted]" : dossier.resumeText)
        \(dossier.workSummary)

        Transcript / chronology:
        \(dossier.transcriptNotes)

        School notes:
        \(schoolSummary.fitList.joined(separator: "\n"))

        Prompt studio mode: \(promptMode.rawValue)
        Target school: \(targetSchool)
        Extra notes: \(customNotes.isEmpty ? "None." : customNotes)

        Please respond in this structure:
        1. Overall read
        2. Strongest asset
        3. Biggest liability
        4. Specific fixes
        5. Next 3 moves

        Be direct, strategic, and law-admissions-focused. Flag anything that depends on official school data.
        """
    }
}
