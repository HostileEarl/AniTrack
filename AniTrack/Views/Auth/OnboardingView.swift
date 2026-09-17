//
//  OnboardingView.swift
//  AniTrack — SCREEN: intro pages
//

import SwiftUI

struct OnboardingView: View {

    let onFinish: () -> Void

    @State private var page: Int = 0

    private struct Page: Identifiable {
        let id: Int
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(id: 0, symbol: "map.fill",
             title: "All your fields in one place",
             body: "Keep track of land in different barangays without a notebook for each one."),
        Page(id: 1, symbol: "person.2.fill",
             title: "Give jobs to your team",
             body: "Set the work, see what is late, and know who is on which field today."),
        Page(id: 2, symbol: "chart.bar.fill",
             title: "See what each field gives",
             body: "Every harvest you write down shows which land is doing well.")
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(pages) { item in
                    VStack(spacing: 0) {
                        Spacer()
                        Image(systemName: item.symbol)
                            .font(.system(size: 62, weight: .light))
                            .foregroundStyle(AppTheme.paddy)
                            .padding(.bottom, 32)
                        Text(item.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                        Text(item.body)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(pages) { item in
                    Capsule()
                        .fill(item.id == page ? AppTheme.paddy : AppTheme.paddy.opacity(0.2))
                        .frame(width: item.id == page ? 20 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: page)
                }
            }
            .padding(.bottom, 24)

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Start" : "Next")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
