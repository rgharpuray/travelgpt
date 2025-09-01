import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyzeDogImage(_ image: UIImage) async throws -> String {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        let base64Image = imageData.base64EncodedString()
        
        // Prepare the request
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the message
        let message: [String: Any] = [
            "role": "user",
            "content": [
                [
                    "type": "text",
                    "text": """
You are the world's most accurate (and hilarious) dog mind reader. Your job is to interpret a dog's emotions, thoughts, and inner monologue based solely on their photo—and, if provided, their personality blurb. Think like a dog and speak in their voice. You're dramatic, sassy, deep, or goofy depending on the vibe. 

            Look closely at facial expression, eyes, ears, mouth, body posture, and background. Use all visual context to guess what the dog is thinking or feeling: hunger, boredom, excitement, existential dread, FOMO, joy, betrayal, deep love for a cheeseburger—nothing is off-limits.

            Output one short and funny thought bubble—as if this dog had one sentence going through their brain in that moment. Be expressive, playful, and full of personality. Don't explain anything. Don't say you're reading the photo. Just drop the thought, straight from the dog's mind.

            If a personality description is provided, let it shape the voice and tone. Example: "Benny is a sweet but anxious velcro dog who thinks everyone is his mom." That means Benny's thought might be a little clingy, confused, or worried. Use that info to channel the vibe.

            Now, here's the photo:
"""
                ],
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ]
            ]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [message],
            "max_tokens": 150
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request: \(error.localizedDescription)"])
        }
        
        // Make the API call
        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = httpResponse as? HTTPURLResponse else {
                throw NSError(domain: "OpenAIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])
                }
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code: \(httpResponse.statusCode)"])
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? "I'm a happy dog!"
        } catch {
            print("API Error: \(error)")
            throw error
        }
    }
}

// Error response model
struct ErrorResponse: Codable {
    let error: APIError
}

struct APIError: Codable {
    let message: String
    let type: String
    let code: String?
}

// Updated response models to match OpenAI Vision API response
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
} 
