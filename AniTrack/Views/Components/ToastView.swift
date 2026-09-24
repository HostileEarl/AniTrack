//
//  ToastView.swift
//  AniTrack — REUSABLE COMPONENT
//
//  The short confirmation that appears at the bottom after something is saved.
//

import SwiftUI
// ObservableObject lives in Combine. Older Xcode versions re-exported it
// through SwiftUI, so this import was not needed; Xcode 26 requires it.
import Combine

@MainActor
final class ToastController: ObservableObject {

    @Published private(set) var message: String?

    private var dismissWork: DispatchWorkItem?

    func show(_ text: String) {
        dismissWork?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            message = text
        }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.message = nil
            }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }
}

struct ToastOverlay: View {

    @ObservedObject var toasts: ToastController

    var body: some View {
        VStack {
            Spacer()
            if let message = toasts.message {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.shoot)
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(AppTheme.ink.opacity(0.92))
                )
                .padding(.bottom, 90)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }
}
