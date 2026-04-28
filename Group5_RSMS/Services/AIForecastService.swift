
import Foundation

class AIForecastService {
    
    // MARK: - Configuration
    private let groqKey = "api"
    private let modelName = "llama-3.1-8b-instant" // Latest high-speed model
    
    struct GroqResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable {
            let message: Message
        }
        struct Message: Decodable {
            let content: String
        }
    }
    
    /// Sends dashboard context to Groq AI and requests structured insights.
    func fetchInsights(context: String) async throws -> (predictions: [String], suggestions: [String], bestCategory: String, suggestion: String, detailed: String) {
        
        guard groqKey != "YOUR_GROQ_API_KEY_HERE" && !groqKey.isEmpty else {
            // Fallback mock response if API key is not configured.
            return (
                predictions: ["Revenue surge expected.", "AOV to hit new peak.", "Customer growth trending up."],
                suggestions: ["Restock Jewellery.", "Launch VIP campaign.", "Optimize ad spend."],
                bestCategory: "Jewellery",
                suggestion: "Focus on high-value Jewellery.",
                detailed: "AI Forecast is in demo mode. Please add a Groq API key."
            )
        }
        
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        let systemPrompt = """
        You are an elite retail analytics AI. Analyze the provided dashboard metrics.
        Return strictly a JSON object. No conversational filler.
        
        Keys required:
        1. "predictions": Array of 3 short, data-driven bullets (max 10 words each).
        2. "suggestions": Array of 3 actionable tactics (max 8 words each).
        3. "best_performing_category": Name of the leading category.
        4. "suggested_action": A single punchy tactical move (max 8 words).
        5. "detailed_analysis": A single powerful summary sentence (max 18 words).
        """
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Here is the data: \(context)"]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.2
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(groqKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("Groq API Error: \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        let jsonString = decoded.choices.first?.message.content ?? ""
        
        struct AIResult: Decodable {
            let predictions: [String]
            let suggestions: [String]
            let best_performing_category: String
            let suggested_action: String
            let detailed_analysis: String
        }
        
        if let jsonData = jsonString.data(using: .utf8),
           let result = try? JSONDecoder().decode(AIResult.self, from: jsonData) {
            return (
                predictions: result.predictions,
                suggestions: result.suggestions,
                bestCategory: result.best_performing_category,
                suggestion: result.suggested_action,
                detailed: result.detailed_analysis
            )
        }
        
        throw URLError(.cannotParseResponse)
    }

    /// Forensic audit diagnosis using Groq AI.
    func fetchAuditDiagnosis(sku: String, productName: String, expected: Int, actual: Int, historyLogs: [String]) async throws -> String {
        guard groqKey != "YOUR_GROQ_API_KEY_HERE" && !groqKey.isEmpty else {
            return "AI Diagnosis unavailable without API key."
        }

        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        let historyString = historyLogs.joined(separator: "\n")
        
        let prompt = """
        Analyze this inventory discrepancy:
        Product: \(productName) (SKU: \(sku))
        Expected: \(expected), Actual: \(actual), Diff: \(actual - expected)
        History: \(historyString)
        
        Identify the likely cause in 1 sentence (max 15 words).
        """

        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.1
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(groqKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return "AI diagnostic engine offline."
        }

        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        return decoded.choices.first?.message.content ?? "Unable to diagnose."
    }
}
