//
//  SplashView.swift
//  AniTrack — SCREEN: opening screen
//

import SwiftUI

struct SplashView: View {

    let onFinish: () -> Void

    @State private var pulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Wordmark(large: true)
                .padding(.bottom, 26)

            Text("Farm operations companion")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .padding(.bottom, 44)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.paddy.opacity(pulse ? 0.9 : 0.25))
                        .frame(width: 6, height: 6)
                        .animation(
                            .easeInOut(duration: 0.9)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: pulse
                        )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
        .onAppear {
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinish()
            }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
