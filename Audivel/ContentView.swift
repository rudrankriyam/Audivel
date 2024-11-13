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
  
  private let config = Configuration.shared
  
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("SakuraKit Demo")
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
        
        Button(action: generateAudio) {
          if isGenerating {
            ProgressView()
          } else {
            Text("Generate Audio")
              .bold()
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(config.playHTAPIKey.isEmpty || config.playHTUserID.isEmpty || sourceURL.isEmpty || isGenerating)
      }
    }
  }
  
  private func generateAudio() {
    Task {
      isGenerating = true
      defer { isGenerating = false }
      
      do {
        let playAI = PlayAI(apiKey: config.playHTAPIKey, userId: config.playHTUserID)
        let request = PlayNoteRequest(
          sourceFileUrl: URL(string: sourceURL)!,
          synthesisStyle: .podcast,
          voice1: .angelo,
          voice2: .nia
        )
        
        let response = try await playAI.createPlayNote(request)
        // Handle response here
      } catch {
        print("Error: \(error)")
      }
    }
  }
}

#Preview {
  ContentView()
}
