import SwiftUI

/// 音量指示條（用於 RecordingOverlay 等其他地方）
struct AudioLevelView: View {
    var level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 3)
                    .fill(level > 0.7 ? Color.red : Color.green)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.05), value: level)
            }
        }
    }
}
