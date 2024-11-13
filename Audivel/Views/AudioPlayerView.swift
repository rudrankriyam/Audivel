import SwiftUI
import AVKit
import Orb

/// A view that provides audio playback functionality using AVPlayer
struct AudioPlayerView: View {
  /// The URL of the audio file to play
  let audioURL: URL
  
  /// The AVPlayer instance used for audio playback
  @State private var audioPlayer = AVPlayer()
  
  /// Whether audio is currently playing
  @State private var isPlaying = false
  
  /// Current playback position in seconds
  @State private var currentTime: TimeInterval = 0
  
  /// Total duration of the audio in seconds
  @State private var duration: TimeInterval = 0
  
  /// Current playback speed multiplier
  @State private var playbackRate: Float = 1.0
  
  /// Whether the audio is currently loading
  @State private var isLoading = false

  private let orbConfig = OrbConfiguration(
    backgroundColors: [.purple, .pink, .blue],
    glowColor: .white,
    coreGlowIntensity: 1.5,
    speed: 45
)

  var body: some View {
    VStack {
      Spacer()

      ZStack {
        if isLoading {
          ProgressView("Loading audio...")
        } else if isPlaying {
          OrbView(configuration: orbConfig)
            .frame(width: 250, height: 250)
            .transition(.scale.combined(with: .opacity))
        } else {
          Image(systemName: isPlaying ? "waveform.circle.fill" : "waveform")
            .font(.system(size: 60))
            .foregroundStyle(isPlaying ? .blue : .secondary)
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
            .font(.title)
        }
        .disabled(duration == 0)

        Button {
          isPlaying ? pause() : play()
        } label: {
          Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 85))
        }
        .buttonStyle(.plain)
        .disabled(duration == 0)

        Button {
          seek(to: min(duration, currentTime + 15))
        } label: {
          Image(systemName: "goforward.15")
            .font(.title)
        }
        .disabled(duration == 0)
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
      audioPlayer.pause()
    }
  }

  private func setupAudioPlayer() {
    audioPlayer = AVPlayer(url: audioURL)
    
    let asset = AVAsset(url: audioURL)

    Task {
      let durationTime = try? await asset.load(.duration)
      await MainActor.run {
        duration = CMTimeGetSeconds(durationTime ?? .zero)
      }
    }
  }

  private func play() {
    audioPlayer.play()
    isPlaying = true
  }

  private func pause() {
    audioPlayer.pause()
    isPlaying = false
  }

  private func seek(to time: TimeInterval) {
    let cmTime = CMTime(seconds: time, preferredTimescale: 1)
    audioPlayer.seek(to: cmTime)
    currentTime = time
  }

  private func setPlaybackRate(_ rate: Float) {
    audioPlayer.rate = rate
    playbackRate = rate
  }

  private func startTimeObserver() {
    let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
      currentTime = CMTimeGetSeconds(time)
      if audioPlayer.timeControlStatus == .paused && currentTime >= duration {
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
          debugPrint("Audio saved successfully")
        }
      } catch {
        debugPrint("Error saving audio: \(error.localizedDescription)")
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
