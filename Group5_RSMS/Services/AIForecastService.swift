
import Foundation

class AIForecastService {
    
//     private let geminiKey = "api"
    // TODO: Securely inject this via an environment variable or Supabase Edge Function.
    // For now, replace with your actual Google Gemini API key.
    private let geminiKey = "AIzaSyCjdPPAD1O7tZF3PIbyfMg54TPh6d6yS6E"
    
    struct GeminiResponse: Decodable {
        let candidates: [Candidate]?
        
        struct Candidate: Decodable {
            let content: Content
        }
        
        struct Content: Decodable {
            let parts: [Part]
        }
        
        struct Part: Decodable {
            let text: String
        }
    }
    
    /// Dynamically finds a supported model for the provided API key
    private func getValidModelName() async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(geminiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct ModelsRes: Decodable {
            struct Model: Decodable {
                let name: String
                let supportedGenerationMethods: [String]?
            }
            let models: [Model]
        }
        
        let res = try JSONDecoder().decode(ModelsRes.self, from: data)
        // Try to find a flash model first
        if let flash = res.models.first(where: { $0.supportedGenerationMethods?.contains("generateContent") == true && $0.name.contains("flash") }) {
            return flash.name // usually "models/gemini-1.5-flash"
        }
        // Fallback to any model that supports generateContent
        if let fallback = res.models.first(where: { $0.supportedGenerationMethods?.contains("generateContent") == true }) {
            return fallback.name
        }
        
        return "models/gemini-1.5-flash"
    }
    
    /// Sends dashboard context to the AI and requests both short insights and a detailed analysis.
    func fetchInsights(context: String) async throws -> (predictions: [String], suggestions: [String], bestCategory: String, suggestion: String, detailed: String) {
        guard geminiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            // Fallback mock response if API key is not configured.
            return (
                predictions: ["Revenue surge expected.", "AOV to hit new peak.", "Customer growth trending up."],
                suggestions: ["Restock Jewellery.", "Launch VIP campaign.", "Optimize ad spend."],
                bestCategory: "Jewellery",
                suggestion: "Focus on high-value Jewellery.",
                detailed: "Detailed analysis placeholder."
            )
        }
        
        let modelName = try await getValidModelName()
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/\(modelName):generateContent?key=\(geminiKey)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        You are an elite retail analytics AI.
        Analyze the provided dashboard metrics.
        CRITICAL: Be extremely concise. Avoid wordy explanations. Use punchy, actionable language.
        Return strictly a JSON object with these keys:
        1. "predictions": Array of 3 ultra-short, data-driven bullets (max 12 words each).
        2. "suggestions": Array of 3 concise, actionable tactics (max 10 words each).
        3. "best_performing_category": Name of the leading category.
        4. "suggested_action": A single punchy tactical move (max 10 words).
        5. "detailed_analysis": A single, powerful summary sentence (max 20 words).
        
        Example:
        {
          "predictions": ["Revenue likely up 12% following recent traffic surge.", "Watch volume to increase 20% by Tuesday.", "Retention rate stabilized at 85%."],
          "suggestions": ["Restock luxury watches immediately.", "Email high-AOV customers a private offer.", "Shift inventory to New Delhi boutique."],
          "best_performing_category": "Luxury Watches",
          "suggested_action": "Restock premium watches and blast VIP offers.",
          "detailed_analysis": "Rising high-end traffic confirms a strong 30-day growth trend for luxury accessories."
        }
        
        Here is the current dashboard data context:
        \(context)
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Gemini API Error: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let content = decoded.candidates?.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        // Remove markdown formatting if Gemini wrapped the JSON array in ```json ... ```
        var cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.hasPrefix("```json") {
            cleanContent = cleanContent.replacingOccurrences(of: "```json", with: "")
        }
        if cleanContent.hasSuffix("```") {
            cleanContent = cleanContent.replacingOccurrences(of: "```", with: "")
        }
        
        struct GeminiAIResult: Decodable {
            let predictions: [String]
            let suggestions: [String]
            let best_performing_category: String
            let suggested_action: String
            let detailed_analysis: String
        }
        
        if let data = cleanContent.data(using: .utf8),
           let result = try? JSONDecoder().decode(GeminiAIResult.self, from: data) {
            return (predictions: result.predictions, 
                    suggestions: result.suggestions,
                    bestCategory: result.best_performing_category,
                    suggestion: result.suggested_action,
                    detailed: result.detailed_analysis)
        } else {
            // Fallback if AI fails to return proper JSON object
            return (predictions: ["Revenue growth predicted."], 
                    suggestions: ["Maintain inventory."],
                    bestCategory: "Luxury Goods",
                    suggestion: "Maintain current strategy.",
                    detailed: "Analysis generated but failed to parse into detailed view.")
        }
    }

    /// Uses Gemini to analyze audit history and provide a forensic diagnosis for a discrepancy.
    func fetchAuditDiagnosis(sku: String, productName: String, expected: Int, actual: Int, historyLogs: [String]) async throws -> String {
        guard geminiKey != "YOUR_GEMINI_API_KEY" && !geminiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let modelName = try await getValidModelName()
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/\(modelName):generateContent?key=\(geminiKey)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        let historyString = historyLogs.joined(separator: "\n")
        let prompt = """
        You are a forensic retail auditor.
        A discrepancy has been found for:
        Product: \(productName) (SKU: \(sku))
        Expected Stock: \(expected)
        Actual Physical Count: \(actual)
        Difference: \(actual - expected)

        Here is the recent audit history for this item:
        \(historyString)

        Based ONLY on the database history records provided below, identify the pattern and provide a BRIEF fix (max 20 words).
        Format: [Simple cause based on database records]. Tap "[Button Name]" to fix it.
        Example: 'Three previous receiving errors found. Tap "Approve Fix" to sync.'
        """

        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.4]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else { return "Failed to reach AI diagnostic engine." }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return decoded.candidates?.first?.content.parts.first?.text ?? "Unable to generate diagnosis."
    }
}
