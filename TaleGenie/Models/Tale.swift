import Foundation

struct Tale: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let content: String
    let createdAt: Date
    let audioURL: URL?
    
    init(prompt: String, content: String, audioURL: URL? = nil) {
        self.id = UUID()
        self.prompt = prompt
        self.content = content
        self.createdAt = Date()
        self.audioURL = audioURL
    }
}

class TaleStore: ObservableObject {
    @Published var tales: [Tale] = []
    private let saveKey = "savedTales"
    
    init() {
        loadTales()
    }
    
    func saveTale(_ tale: Tale) {
        tales.append(tale)
        saveTales()
    }
    
    private func loadTales() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decodedTales = try? JSONDecoder().decode([Tale].self, from: data) {
            tales = decodedTales
        }
    }
    
    private func saveTales() {
        if let encoded = try? JSONEncoder().encode(tales) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 