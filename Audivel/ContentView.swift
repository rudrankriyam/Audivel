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
  
  private let config = Configuration.shared
  
  var body: some View {
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
        
        // API Status Section
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("API Status:")
              .foregroundStyle(.secondary)
            Image(systemName: !config.playHTAPIKey.isEmpty && !config.playHTUserID.isEmpty ? 
              "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundColor(!config.playHTAPIKey.isEmpty && !config.playHTUserID.isEmpty ? 
                .green : .red)
          }
          .font(.footnote)
        }
        .padding(.horizontal)
        
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
        .padding(.top, 8)
        
        // Generation Status and Audio Link
        if isGenerating {
          VStack(spacing: 8) {
            ProgressView()
            Text("Generating audio...")
              .foregroundStyle(.secondary)
          }
          .padding(.top)
        }
        
        if let audioURL {
          Link(destination: audioURL) {
            HStack {
              Image(systemName: "play.circle.fill")
              Text("Play Generated Audio")
            }
            .font(.headline)
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
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
        self.sourceURL = url.absoluteString
        generatePlayNote()
      case .failure(let error):
        debugPrint("Error importing file: \(error)")
      }
    }
  }
  
  private func generatePlayNote() {
    Task {
      isGenerating = true
      defer { isGenerating = false }
      
      do {
        let playAI = PlayAI(apiKey: config.playHTAPIKey, userId: config.playHTUserID)
        
        guard let sourceURL = URL(string: sourceURL) else {
          return
        }
        
        let request = PlayNoteRequest(
          sourceFileUrl: sourceURL,
          synthesisStyle: .podcast,
          voice1: .angelo,
          voice2: .nia
        )
        
        let response = try await playAI.createAndAwaitPlayNote(request, statusHandler: { status in
          debugPrint("Status: \(status)")
        })
        
        if let audioURL = response.audioUrl {
          self.audioURL = URL(string: audioURL)
          debugPrint("Audio URL: \(audioURL)")
        }
      } catch {
        debugPrint("Error: \(error)")
      }
    }
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
