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
  
  private let config = Configuration.shared
  
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("PlayNote Generator")
          .font(.largeTitle)
          .padding()
        
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("API Key Status:")
            Image(systemName: !config.playHTAPIKey.isEmpty ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundColor(!config.playHTAPIKey.isEmpty ? .green : .red)
          }
          
          HStack {
            Text("User ID Status:")
            Image(systemName: !config.playHTUserID.isEmpty ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundColor(!config.playHTUserID.isEmpty ? .green : .red)
          }
          
          TextField("Source URL", text: $sourceURL)
            .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
        
        Button(action: generatePlayNote) {
          if isGenerating {
            ProgressView()
          } else {
            Text("Generate PlayNote")
              .bold()
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(config.playHTAPIKey.isEmpty || config.playHTUserID.isEmpty || sourceURL.isEmpty || isGenerating)
        
        if let audioURL {
          Link("Open Audio", destination: audioURL)
            .font(.headline)
            .foregroundColor(.blue)
        }
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

#Preview {
  ContentView()
}
