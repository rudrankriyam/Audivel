//
//  ContentView.swift
//  Audivel
//
//  Created by Rudrank Riyam on 11/13/24.
//

import SwiftUI
import SakuraKit

struct ContentView: View {
  @State private var sourceURL = ""
  @State private var isGenerating = false
  @State private var audioURL: URL?
  @State private var showingFileImporter = false
  @State private var showingURLInput = false
  @State private var selectedVoice1 = PlayNoteVoice.angelo
  @State private var selectedVoice2 = PlayNoteVoice.nia
  @State private var selectedStyle = PlayNoteSynthesisStyle.podcast
  @State private var selectedPDF: URL?
  @State private var conversionProgress = 0.0
  @State private var estimatedTime: TimeInterval?
  @State private var conversionStatus = ""
  
  private let config = Configuration.shared
  
  var body: some View {
    ZStack {
      ScrollView {
        VStack(spacing: 24) {
          // Title and Instructions
          VStack(spacing: 8) {
            Text("Audio from PDF")
              .font(.system(size: 34, weight: .bold))
            
            Text("Convert your PDF files into audio with one tap!")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 32)
          
          // Selected PDF Display
          if let selectedPDF {
            PDFPreview(url: selectedPDF)
          }
          
          // Import Options
          VStack(spacing: 16) {
            Button(action: { showingFileImporter = true }) {
              ImportButton(
                systemName: "doc.fill",
                title: "Choose PDF",
                subtitle: "Select from Files"
              )
            }
            
            Button(action: { showingURLInput = true }) {
              ImportButton(
                systemName: "link",
                title: "Import URL",
                subtitle: "Paste PDF link"
              )
            }
          }
          .padding(.horizontal)
          
          // Conversion Settings
          VStack(alignment: .leading, spacing: 20) {
            Text("Conversion Settings")
              .font(.headline)
            
            // Voice Selection
            VStack(alignment: .leading, spacing: 12) {
              Text("Primary Voice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              
              Picker("Primary Voice", selection: $selectedVoice1) {
                ForEach([
                  PlayNoteVoice.angelo, .arsenio, .cillian, .timo,
                  .dexter, .miles, .briggs, .deedee, .nia, .inara,
                  .constanza, .gideon, .casper, .mitch, .ava
                ], id: \.id) { voice in
                  VoiceOption(voice: voice)
                    .tag(voice)
                }
              }
              .pickerStyle(.menu)
              
              Text("Secondary Voice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              
              Picker("Secondary Voice", selection: $selectedVoice2) {
                ForEach([
                  PlayNoteVoice.nia, .angelo, .arsenio, .cillian,
                  .timo, .dexter, .miles, .briggs, .deedee, .inara,
                  .constanza, .gideon, .casper, .mitch, .ava
                ], id: \.id) { voice in
                  VoiceOption(voice: voice)
                    .tag(voice)
                }
              }
              .pickerStyle(.menu)
            }
            
            // Synthesis Style
            VStack(alignment: .leading, spacing: 12) {
              Text("Synthesis Style")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              
              Picker("Style", selection: $selectedStyle) {
                Text("Podcast").tag(PlayNoteSynthesisStyle.podcast)
                Text("Executive Briefing").tag(PlayNoteSynthesisStyle.executiveBriefing)
                Text("Children's Story").tag(PlayNoteSynthesisStyle.childrensStory)
                Text("Debate").tag(PlayNoteSynthesisStyle.debate)
              }
              .pickerStyle(.segmented)
            }
          }
          .padding()
          .background(Color(.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal)
          
          // Generate Button
          Button(action: generatePlayNote) {
            if isGenerating {
              ProgressView()
                .controlSize(.large)
            } else {
              Text("Generate Audio")
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(sourceURL.isEmpty || isGenerating)
          .padding(.horizontal)
          
          if let audioURL {
            NavigationLink {
              AudioPlayerView(audioURL: audioURL)
            } label: {
              Label("Play Generated Audio", systemImage: "play.circle.fill")
                .font(.headline)
            }
            .buttonStyle(.bordered)
          }
        }
      }
      .blur(radius: isGenerating ? 3 : 0)
      
      // Overlay Progress View when generating
      if isGenerating {
        Color(.systemBackground)
          .opacity(0.8)
          .ignoresSafeArea()
        
        ConversionProgressView(
          status: conversionStatus.isEmpty ? "Converting PDF to audio...\nThis may take a few minutes" : conversionStatus,
          progress: conversionProgress,
          estimatedTime: estimatedTime
        ) {
          cancelGeneration()
        }
        .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.spring(duration: 0.3), value: isGenerating)
    .sheet(isPresented: $showingURLInput) {
      URLInputSheet(sourceURL: $sourceURL, isPresented: $showingURLInput) {
        generatePlayNote()
      }
    }
    .fileImporter(
      isPresented: $showingFileImporter,
      allowedContentTypes: [.pdf]
    ) { result in
      switch result {
      case .success(let url):
        self.selectedPDF = url
        self.sourceURL = url.absoluteString
      case .failure(let error):
        print("Error importing file: \(error.localizedDescription)")
      }
    }
  }
  
  private func generatePlayNote() {
    Task {
      isGenerating = true
      conversionProgress = 0
      conversionStatus = "Initializing conversion..."
      
      do {
        let playAI = PlayAI(apiKey: config.playHTAPIKey, userId: config.playHTUserID)
        
        guard let sourceURL = URL(string: sourceURL) else { return }
        
        let request = PlayNoteRequest(
          sourceFileUrl: sourceURL,
          synthesisStyle: selectedStyle,
          voice1: selectedVoice1,
          voice2: selectedVoice2
        )
        
        let response = try await playAI.createAndAwaitPlayNote(request) { status in
          // Update progress based on status
          Task { @MainActor in
            updateProgress(for: status)
          }
        }
        
        if let audioURL = response.audioUrl {
          self.audioURL = URL(string: audioURL)
          conversionStatus = "Conversion complete!"
          // Show completion state briefly before dismissing
          try? await Task.sleep(for: .seconds(1))
        }
      } catch {
        conversionStatus = "Error: \(error.localizedDescription)"
        try? await Task.sleep(for: .seconds(2))
      }
      
      isGenerating = false
    }
  }
  
  private func updateProgress(for status: String) {
    switch status.lowercased() {
    case let s where s.contains("processing"):
      conversionProgress = 0.3
      conversionStatus = "Processing PDF content..."
      estimatedTime = 240 // 4 minutes
      
    case let s where s.contains("generating"):
      conversionProgress = 0.6
      conversionStatus = "Generating audio..."
      estimatedTime = 180 // 3 minutes
      
    case let s where s.contains("finalizing"):
      conversionProgress = 0.9
      conversionStatus = "Finalizing audio..."
      estimatedTime = 60 // 1 minute
      
    case let s where s.contains("complete"):
      conversionProgress = 1.0
      conversionStatus = "Conversion complete!"
      estimatedTime = nil
      
    default:
      break
    }
  }
  
  private func cancelGeneration() {
    // Implement cancellation logic here
    Task {
      // Add API call to cancel conversion if supported
      isGenerating = false
      conversionStatus = "Conversion cancelled"
      try? await Task.sleep(for: .seconds(1))
    }
  }
}

// Supporting Views
struct VoiceOption: View {
  let voice: PlayNoteVoice
  
  var body: some View {
    HStack {
      Text(voice.name)
      Text("(\(voice.accent))")
        .foregroundStyle(.secondary)
    }
  }
}

struct PDFPreview: View {
  let url: URL
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Selected PDF")
        .font(.headline)
      
      HStack {
        Image(systemName: "doc.fill")
          .font(.title2)
          .foregroundStyle(.blue)
        
        VStack(alignment: .leading) {
          Text(url.lastPathComponent)
            .lineLimit(1)
          
          Text(url.pathExtension.uppercased())
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .background(Color(.systemGray6))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding(.horizontal)
  }
}

// MARK: - Supporting Views

struct ImportButton: View {
  let systemName: String
  let title: String
  let subtitle: String
  
  var body: some View {
    HStack {
      Image(systemName: systemName)
        .font(.title2)
        .frame(width: 44, height: 44)
        .background(.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      
      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
    }
    .padding()
    .background(.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct URLInputSheet: View {
  @Binding var sourceURL: String
  @Binding var isPresented: Bool
  let onSubmit: () -> Void
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          TextField("PDF URL", text: $sourceURL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        } footer: {
          Text("Enter the URL of the PDF file you want to convert to audio.")
        }
      }
      .navigationTitle("Import PDF URL")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            isPresented = false
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Import") {
            isPresented = false
            onSubmit()
          }
          .disabled(sourceURL.isEmpty)
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
