//
//  AIForecastService.swift
//  Group5_RSMS
//
//  Handles requests to external AI APIs (Google Gemini) to generate
//  predictive insights based on dashboard context.
//

import Foundation

class AIForecastService {
    
    // TODO: Securely inject this via an environment variable or Supabase Edge Function.
    // For now, replace with your actual Google Gemini API key.
    private let geminiKey = "YOUR_GEMINI_API_KEY"
    
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
        Return strictly a JSON object with these keys:
        1. "predictions": An array of 3 highly detailed, data-driven revenue or behavior predictions. Include specific percentages or volumes based on the data.
        2. "suggestions": An array of 3 highly actionable, strategic suggestions to improve specific KPIs.
        3. "best_performing_category": The name of the category expected to lead growth in the next 30 days.
        4. "suggested_action": A single primary strategic action for the week.
        5. "detailed_analysis": A single comprehensive paragraph (3-4 sentences) explaining the reasoning behind the forecast.
        
        Example:
        {
          "predictions": ["Revenue is projected to rise by 12.4% over the next 14 days.", "Luxury watches will likely see a 20% volume surge.", "Customer retention rate is trending towards a 5% improvement."],
          "suggestions": ["Immediate restock of high-demand watch models is critical.", "Target high-AOV customers with a premium loyalty campaign.", "Optimize inventory for the upcoming revenue peak on Tuesday."],
          "best_performing_category": "Luxury Watches",
          "suggested_action": "Restock premium watches and run a targeted VIP promotion.",
          "detailed_analysis": "The upcoming 30 days show a strong upward trend in revenue driven primarily by the luxury watches segment..."
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
}
