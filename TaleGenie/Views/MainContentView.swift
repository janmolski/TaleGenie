import SwiftUI
import AVFoundation

struct MainContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var taleStore: TaleStore
    @EnvironmentObject var openAIService: OpenAIService
    
    @State private var prompt = ""
    @State private var currentTale = ""
    @State private var isGenerating = false
    @State private var showingTaleList = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter your story prompt...", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !currentTale.isEmpty || isGenerating {
                            Text(currentTale)
                                .padding()
                                .animation(.easeIn, value: currentTale)
                            
                            if !currentTale.isEmpty {
                                HStack {
                                    Button(action: {
                                        Task {
                                            isPlayingAudio = true
                                            do {
                                                let stream = try await openAIService.generateAudioStream(from: currentTale)
                                                audioPlayer = try await openAIService.playAudioStream(stream)
                                                audioPlayer?.play()
                                            } catch {
                                                print("Error generating audio: \(error)")
                                            }
                                            isPlayingAudio = false
                                        }
                                    }) {
                                        Label(isPlayingAudio ? "Playing..." : "Read Aloud", 
                                              systemImage: isPlayingAudio ? "stop.circle.fill" : "play.circle.fill")
                                    }
                                    .disabled(isPlayingAudio)
                                    
                                    Button(action: {
                                        let tale = Tale(prompt: prompt, content: currentTale)
                                        taleStore.saveTale(tale)
                                    }) {
                                        Label("Save Tale", systemImage: "square.and.arrow.down")
                                    }
                                }
                                .padding(.horizontal)
                                
                                if isPlayingAudio {
                                    ProgressView()
                                        .progressViewStyle(.linear)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    Task {
                        isGenerating = true
                        currentTale = ""
                        
                        do {
                            var fullStory = ""
                            let stream = try await openAIService.generateTale(from: prompt)
                            for try await text in stream {
                                fullStory += text
                                await MainActor.run {
                                    currentTale = fullStory
                                }
                            }
                        } catch {
                            print("Error generating tale: \(error)")
                        }
                        
                        isGenerating = false
                    }
                }) {
                    HStack {
                        Text(isGenerating ? "Generating..." : "Generate Tale")
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(prompt.isEmpty || isGenerating)
                .padding()
            }
            .navigationTitle("TaleGenie")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTaleList.toggle() }) {
                        Image(systemName: "list.bullet")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { authManager.signOut() }) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                    }
                }
            }
            .sheet(isPresented: $showingTaleList) {
                TaleListView()
            }
        }
    }
}

#Preview {
    MainContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(TaleStore())
        .environmentObject(OpenAIService())
} 