import SwiftUI

/// A view that displays the current progress of audio conversion
struct ConversionProgressView: View {
  let status: String
  let progress: Double
  let estimatedTime: TimeInterval?
  let onCancel: () -> Void

  @State private var rotation = 0.0

  var body: some View {
    VStack(spacing: 32) {
      // Progress Animation
      ZStack {
        // Background circle
        Circle()
          .stroke(Color(.systemGray5), lineWidth: 8)
          .frame(width: 120, height: 120)

        // Progress circle
        Circle()
          .trim(from: 0, to: progress)
          .stroke(Color.accentColor, style: StrokeStyle(
            lineWidth: 8,
            lineCap: .round
          ))
          .frame(width: 120, height: 120)
          .rotationEffect(.degrees(-90))

        // Center icon
        Image(systemName: "waveform")
          .font(.system(size: 40))
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(rotation))
          .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
              rotation = 360
            }
          }
      }

      // Status Text
      VStack(spacing: 16) {
        Text(status)
          .font(.headline)
          .multilineTextAlignment(.center)

        if let estimatedTime {
          HStack {
            Image(systemName: "clock")
            Text("Estimated time: \(formatTime(estimatedTime))")
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
      }

      // Cancel Button
      Button(role: .destructive, action: onCancel) {
        Text("Cancel Conversion")
          .font(.subheadline.bold())
      }
      .buttonStyle(.bordered)
    }
    .padding()
  }

  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return "\(minutes)m \(seconds)s"
  }
}

#Preview {
  ZStack {
    Color(.systemGray6)
      .ignoresSafeArea()
    
    ConversionProgressView(
      status: "Converting PDF to audio...\nThis may take a few minutes",
      progress: 0.7,
      estimatedTime: 180
    ) {
      print("Cancelled")
    }
    .padding()
  }
}
