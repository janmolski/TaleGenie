import Foundation
import AVFoundation

class OpenAIService: ObservableObject {
    private var apiKey: String = "" // Add your OpenAI API key here
    
    @Published var isGenerating = false
    @Published var isGeneratingAudio = false
    
    enum OpenAIError: Error {
        case invalidResponse
        case failedToGenerateText
        case failedToGenerateAudio
        case invalidAudioData
    }
    
    func generateTale(from prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let message = [
            "role": "system",
            "content": "You are a creative storyteller who writes engaging fairytales for children. Keep the stories appropriate for all ages and include moral lessons. Keep the stories concise, around 200-300 words."
        ]
        
        let userMessage = [
            "role": "user",
            "content": "Create a fairytale about: \(prompt)"
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": [message, userMessage],
            "stream": true,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw OpenAIError.invalidResponse
                    }
                    
                    var buffer = ""
                    
                    for try await byte in bytes {
                        if let char = String(bytes: [byte], encoding: .utf8) {
                            buffer += char
                            
                            if buffer.contains("\n") {
                                let lines = buffer.components(separatedBy: "\n")
                                buffer = lines.last ?? ""
                                
                                for line in lines.dropLast() {
                                    if line.hasPrefix("data: ") {
                                        if line == "data: [DONE]" {
                                            continuation.finish()
                                            return
                                        }
                                        
                                        let jsonString = String(line.dropFirst(6))
                                        if let jsonData = jsonString.data(using: .utf8),
                                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                           let choices = json["choices"] as? [[String: Any]],
                                           let delta = choices.first?["delta"] as? [String: Any],
                                           let content = delta["content"] as? String {
                                            continuation.yield(content)
                                        }
                                    }
                                }
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
    
    func generateAudioStream(from text: String) async throws -> AsyncThrowingStream<Data, Error> {
        let endpoint = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": "alloy",
            "response_format": "mp3",
            "speed": 1.0
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw OpenAIError.invalidResponse
                    }
                    
                    let chunkSize = 32 * 1024 // 32KB chunks
                    var audioData = Data()
                    
                    for try await byte in bytes {
                        audioData.append(byte)
                        
                        if audioData.count >= chunkSize {
                            continuation.yield(audioData)
                            audioData = Data()
                        }
                    }
                    
                    if !audioData.isEmpty {
                        continuation.yield(audioData)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func playAudioStream(_ stream: AsyncThrowingStream<Data, Error>) async throws -> AVAudioPlayer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).mp3")
        
        var audioData = Data()
        for try await chunk in stream {
            audioData.append(chunk)
        }
        
        try audioData.write(to: audioFileURL)
        
        guard let player = try? AVAudioPlayer(contentsOf: audioFileURL) else {
            throw OpenAIError.invalidAudioData
        }
        
        try FileManager.default.removeItem(at: audioFileURL)
        return player
    }
} 