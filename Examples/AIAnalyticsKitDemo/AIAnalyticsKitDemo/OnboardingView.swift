import SwiftUI
import AIAnalyticsKit

// MARK: - Onboarding View

struct OnboardingView: View {

    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "brain.fill",
            imageColor: .purple,
            title: "On-Device AI Analytics",
            body: "AIAnalyticsKit classifies your users entirely on the Neural Engine. No network calls, no data egress — just intelligent personalization that respects privacy.",
            backgroundGradient: [.purple.opacity(0.12), .indigo.opacity(0.06)]
        ),
        OnboardingPage(
            systemImage: "arrow.forward.circle.fill",
            imageColor: .blue,
            title: "How It Works",
            body: "Your app tracks events → AIAnalyticsKit extracts a feature vector → Foundation Models classifies the user → the UI adapts in real-time.",
            backgroundGradient: [.blue.opacity(0.12), .teal.opacity(0.06)]
        ),
        OnboardingPage(
            systemImage: "person.3.fill",
            imageColor: .teal,
            title: "Four User Types",
            body: "Power User, Explorer, Casual, or At-Risk. Each classification unlocks a tailored greeting, accent color, advanced features toggle, and personalized action recommendations.",
            backgroundGradient: [.teal.opacity(0.12), .green.opacity(0.06)]
        ),
    ]

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: pages[currentPage].backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 460)

                Spacer()

                // Bottom controls
                VStack(spacing: 28) {
                    // Page indicator dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? pages[currentPage].imageColor : Color.secondary.opacity(0.3))
                                .frame(width: currentPage == index ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Primary action button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.headline)
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(pages[currentPage].imageColor)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: page.systemImage)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(page.imageColor)
                .frame(width: 120, height: 120)
                .glassEffect(.regular.tint(page.imageColor), in: .circle)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Pipeline Diagram (Page 2 enhancement)

private struct PipelineDiagramView: View {
    let steps = [
        ("list.bullet", "Events", Color.blue),
        ("waveform.path", "Features", Color.purple),
        ("brain.fill", "Predict", Color.indigo),
        ("paintbrush.fill", "Adapt UI", Color.teal),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(steps.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    Image(systemName: steps[i].0)
                        .font(.footnote)
                        .foregroundStyle(steps[i].2)
                    Text(steps[i].1)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if i < steps.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}

// MARK: - Data Model

private struct OnboardingPage {
    let systemImage: String
    let imageColor: Color
    let title: String
    let body: String
    let backgroundGradient: [Color]
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
