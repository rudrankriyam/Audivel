import SwiftUI
import AVKit
import Orb

struct AudioPlayerView: View {
  let audioURL: URL
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var currentTime: TimeInterval = 0
  @State private var duration: TimeInterval = 0
  @State private var playbackRate: Float = 1.0

  // Orb configuration for audio visualization
  private let orbConfig = OrbConfiguration(
    backgroundColors: [.blue, .purple, .indigo],
    glowColor: .white,
    coreGlowIntensity: 1.2,
    showBackground: true,
    showWavyBlobs: true,
    showParticles: true,
    showGlowEffects: true,
    showShadow: true,
    speed: 60
  )

  var body: some View {
    VStack {
      Spacer()

      ZStack {
        if isPlaying {
          OrbView(configuration: orbConfig)
            .frame(width: 200, height: 200)
            .transition(.scale.combined(with: .opacity))
        } else {
          Image(systemName: "waveform")
            .font(.system(size: 60))
            .foregroundStyle(.secondary)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .animation(.spring(duration: 0.6), value: isPlaying)
      .padding()

      Spacer()

      VStack(spacing: 8) {
        HStack {
          Text(formatTime(currentTime))
          Spacer()
          Text(formatTime(duration))
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        Slider(
          value: Binding(
            get: { currentTime },
            set: { seek(to: $0) }
          ),
          in: 0...duration
        )
        .tint(.blue)
      }
      .padding(.horizontal)

      HStack(spacing: 40) {
        Button {
          seek(to: max(0, currentTime - 15))
        } label: {
          Image(systemName: "gobackward.15")
            .font(.title2)
        }

        Button {
          isPlaying ? pause() : play()
        } label: {
          Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 65))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.blue)
        }

        // Forward 15s
        Button {
          seek(to: min(duration, currentTime + 15))
        } label: {
          Image(systemName: "goforward.15")
            .font(.title2)
        }
      }
      .padding()

      Spacer()

      HStack(spacing: 20) {
        Button(action: downloadAudio) {
          Label("Download", systemImage: "arrow.down.circle.fill")
        }
        .buttonStyle(.bordered)

        ShareLink(item: audioURL) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
      }
      .padding()
    }
    .navigationTitle("Audivel Playback")
    .onAppear {
      setupAudioPlayer()
      startTimeObserver()
    }
    .onDisappear {
      audioPlayer?.stop()
    }
  }

  private func setupAudioPlayer() {
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
      audioPlayer?.prepareToPlay()
      duration = audioPlayer?.duration ?? 0
    } catch {
      print("Error setting up audio player: \(error.localizedDescription)")
    }
  }

  private func play() {
    audioPlayer?.play()
    isPlaying = true
  }

  private func pause() {
    audioPlayer?.pause()
    isPlaying = false
  }

  private func seek(to time: TimeInterval) {
    audioPlayer?.currentTime = time
    currentTime = time
  }

  private func setPlaybackRate(_ rate: Float) {
    audioPlayer?.rate = rate
    playbackRate = rate
  }

  private func startTimeObserver() {
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      currentTime = audioPlayer?.currentTime ?? 0
      if audioPlayer?.isPlaying == false && currentTime >= duration {
        isPlaying = false
      }
    }
  }

  private func downloadAudio() {
    Task {
      do {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("audio.wav")

        if FileManager.default.fileExists(atPath: destinationURL.path) {
          try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: audioURL, to: destinationURL)

        await MainActor.run {
          // Show success message
          // You might want to add a toast or alert here
          print("Audio saved successfully")
        }
      } catch {
        print("Error saving audio: \(error.localizedDescription)")
      }
    }
  }

  private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}

#Preview {
  NavigationStack {
    AudioPlayerView(audioURL: URL(string: "https://example.com/audio.wav")!)
  }
}
