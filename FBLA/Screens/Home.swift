
import SwiftUI
import SwiftData

// MARK: - Home

struct Home: View {
    @State private var showWelcome = true
    @State private var showTimer = false
    @StateObject private var vm = CountdownTimerViewModel()

    var body: some View {
        ZStack {
            // Single dynamic animated background behind entire app
            Background3DView(pageIndex: .constant(0), swipeProgress: .constant(0))
                .ignoresSafeArea()

            // Hide Home cards when timer overlay is visible
            if !showTimer {
                ScrollView {
                    VStack(spacing: 16) {

                        // MARK: Branding
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.navy, Theme.navy.opacity(0.85)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "graduationcap.fill")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("FBLA").font(Theme.display(26)).foregroundColor(.primary)
                                        Text("Future Business Leaders of America")
                                            .font(Theme.text(12)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                Text("Home").font(Theme.display(28)).foregroundColor(.primary)

                                HStack(spacing: 10) {
                                    PrimaryCapsuleButton(title: "Add Event", symbol: "calendar.badge.plus") {
                                        Haptics.light()
                                    }
                                    GhostCapsuleButton(title: "Resources", symbol: "book.fill") {
                                        Haptics.light()
                                    }
                                }
                            }
                        }

                        // MARK: Welcome
                        if showWelcome {
                            Card {
                                HStack(alignment: .top, spacing: 12) {
                                    IconBadge(symbol: "sparkles", tint: Theme.red)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Welcome").font(Theme.text(17, weight: .semibold))
                                        Text("Swipe sections or use tabs. Scroll to see actions and your dashboard.")
                                            .font(Theme.text(13)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        Haptics.light()
                                        withAnimation(.easeInOut(duration: 0.25)) { showWelcome = false }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .padding(6)
                                            .background(Circle().fill(Color.gray.opacity(0.12)))
                                    }
                                    .buttonStyle(ScaledButtonStyle(scale: 0.92))
                                    .accessibilityLabel(Text("Dismiss"))
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }

                        // MARK: Quick Actions
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    IconBadge(symbol: "bolt.fill", tint: Theme.red)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Quick Actions").font(Theme.text(17, weight: .semibold))
                                        Text("Start timer, add task, open resources")
                                            .font(Theme.text(13)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                HStack(spacing: 10) {
                                    PrimaryCapsuleButton(title: "Start Timer", symbol: "timer") {
                                        Haptics.medium()
                                        withAnimation(.easeInOut(duration: 0.18)) { showTimer = true }
                                    }
                                    GhostCapsuleButton(title: "Add Task", symbol: "checklist") {
                                        Haptics.light()
                                    }
                                    GhostCapsuleButton(title: "Resources", symbol: "bookmark.fill") {
                                        Haptics.light()
                                    }
                                }
                            }
                        }

                        // MARK: Dashboard Chips
                        Card(dense: true) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dashboard").font(Theme.text(17, weight: .semibold))
                                HStack(spacing: 8) {
                                    dashChip("Events", "calendar")
                                    dashChip("Tasks", "checklist")
                                    dashChip("Resources", "book.closed")
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(16)
                }
                .transition(.opacity)
            }

            // Timer overlay (in-app overlay → background remains visible)
            if showTimer {
                CountdownTimerOverlay(vm: vm) {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.18)) { showTimer = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showTimer)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .background(Color.clear)
    }

    private func dashChip(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
            Text(title).font(Theme.text(13, weight: .semibold))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.gray.opacity(0.12)))
        .overlay(Capsule().stroke(Theme.border))
        .onTapGesture { Haptics.light() }
    }
}

// MARK: - Countdown Timer ViewModel (ultra-light updates)

@MainActor
final class CountdownTimerViewModel: ObservableObject {
    /// Total duration (s)
    @Published private(set) var totalSeconds: Double = 300
    /// Remaining (s)
    @Published private(set) var remainingSeconds: Double = 300
    /// Running flag
    @Published private(set) var isRunning = false

    private var timer: Timer?
    /// Lower tick for zero-lag UI; ring interpolates smoothly
    private let tick: TimeInterval = 0.20

    /// 0...1 progress
    var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(1.0 - max(0, remainingSeconds) / totalSeconds)
    }

    func start() {
        guard !isRunning, remainingSeconds > 0.0 else { return }
        Haptics.success()
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.onTick() }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func pause() {
        guard isRunning else { return }
        Haptics.light()
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        Haptics.warning()
        pause()
        remainingSeconds = totalSeconds
    }

    func setTime(h: Int, m: Int, s: Int) {
        let newTotal = Double(h * 3600 + m * 60 + s)
        totalSeconds = max(1.0, newTotal)
        remainingSeconds = totalSeconds
    }

    private func onTick() {
        guard isRunning else { return }
        remainingSeconds = max(0.0, remainingSeconds - tick)
        if remainingSeconds <= 0.0 {
            isRunning = false
            timer?.invalidate()
            timer = nil
            Haptics.success()
        }
    }
}

// MARK: - Countdown Timer Overlay (chrome-free, scrollable, smooth)

private struct CountdownTimerOverlay: View {
    @ObservedObject var vm: CountdownTimerViewModel
    let onClose: () -> Void

    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var showDuration = false

    var body: some View {
        ZStack {
            Color.clear

            ScrollView {
                VStack(spacing: 16) {

                    TimerCard(
                        progress: vm.progress,
                        displayTime: timeString(vm.remainingSeconds),
                        isRunning: vm.isRunning,
                        onStart: { vm.start() },
                        onPause: { vm.pause() },
                        onReset: { vm.reset() },
                        onToggleExpand: {
                            Haptics.light()
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                                showDuration.toggle()
                            }
                        },
                        isExpanded: showDuration
                    )

                    if showDuration {
                        DurationCard(
                            hours: $hours, minutes: $minutes, seconds: $seconds,
                            onApply: {
                                Haptics.success()
                                vm.setTime(h: hours, m: minutes, s: seconds)
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .opacity))
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Close")
                            .font(Theme.text(15, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.gray.opacity(0.14)))
                }
                .buttonStyle(ScaledButtonStyle(scale: 0.95))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .background(Color.clear)
        }
        .background(Color.clear)
        .ignoresSafeArea(.container, edges: .all)
        .contentShape(Rectangle())
    }

    private func timeString(_ total: Double) -> String {
        let t = max(0, Int(total.rounded(.down)))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%01d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

// MARK: - Timer Card (centered, emissive + unclipped ring)

private struct TimerCard: View {
    let progress: CGFloat
    let displayTime: String
    let isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onToggleExpand: () -> Void
    let isExpanded: Bool

    var body: some View {
        Card(style: .frosted) {
            VStack(spacing: 18) {
                // Adaptive modest reduction + inner padding so ring never hits rounded edges
                let ringSize: CGFloat = UIScreen.main.bounds.width < 380 ? 188 : 198

                EmissiveGoldRingUltra(progress: progress)
                    .frame(width: ringSize, height: ringSize)
                    .padding(18) // critical: keeps glow away from card clip
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(displayTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 12) {
                    if isRunning {
                        PrimaryCapsuleButton(title: "Pause", symbol: "pause.fill") { onPause() }
                        GhostCapsuleButton(title: "Reset", symbol: "arrow.counterclockwise") { onReset() }
                    } else {
                        PrimaryCapsuleButton(title: "Start", symbol: "play.fill") { onStart() }
                        GhostCapsuleButton(title: "Reset", symbol: "arrow.counterclockwise") { onReset() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button { onToggleExpand() } label: {
                    HStack(spacing: 8) {
                        Text("Set Duration").font(Theme.text(14, weight: .semibold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.gray.opacity(0.12)))
                }
                .buttonStyle(ScaledButtonStyle(scale: 0.96))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Duration Card

private struct DurationCard: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onApply: () -> Void

    var body: some View {
        Card(style: .frosted) {
            VStack(spacing: 16) {
                Text("Duration")
                    .font(Theme.text(17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 16) {
                    dialPicker("HR", 0..<24, $hours)
                    dialPicker("MIN", 0..<60, $minutes)
                    dialPicker("SEC", 0..<60, $seconds)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                PrimaryCapsuleButton(title: "Apply", symbol: "checkmark") {
                    onApply()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func dialPicker(
        _ label: String,
        _ range: Range<Int>,
        _ binding: Binding<Int>
    ) -> some View {
        VStack(spacing: 6) {
            Picker(label, selection: binding) {
                ForEach(range, id: \.self) { v in
                    Text(String(format: "%02d", v))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 74, height: 118)
            .clipped()
            .onChange(of: binding.wrappedValue) { _, _ in Haptics.light() }

            Text(label)
                .font(Theme.text(11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Emissive Gold Ring (no continuous animation, true glow, ultra-light)

/// **Zero‑lag emissive ring**:
/// - No TimelineView / rotation / orbit spark
/// - Emissive look from layered glows + plusLighter blend
/// - Only animates when `progress` changes (lightweight)
private struct EmissiveGoldRingUltra: View {
    let progress: CGFloat
    /// Slightly thinner for crisp stroke + room for glows
    private let thickness: CGFloat = 12

    // Gold shades inspired by Background3DView flecks
    private let goldCore = Color(red: 1.00, green: 0.92, blue: 0.55) // bright
    private let goldEdge = Color(red: 1.00, green: 0.86, blue: 0.22) // deeper

    var body: some View {
        ZStack {
            // TRACK (very subtle)
            Circle()
                .stroke(goldCore.opacity(0.16),
                        style: StrokeStyle(lineWidth: thickness, lineCap: .round))

            // MAIN STROKE
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            goldCore,
                            goldCore.opacity(0.95),
                            goldEdge,
                            goldCore.opacity(0.98)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.24), value: progress)

            // INNER GLOW (tight bloom following the stroke)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(goldEdge.opacity(0.55), style: StrokeStyle(lineWidth: thickness))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // OUTER HALO (soft emissive aura)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(goldEdge.opacity(0.25), style: StrokeStyle(lineWidth: thickness + 14))
                .rotationEffect(.degrees(-90))
                .blur(radius: 14)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // VERY OUTER AMBIENT GLOW (extremely subtle)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(goldCore.opacity(0.10), style: StrokeStyle(lineWidth: thickness + 28))
                .rotationEffect(.degrees(-90))
                .blur(radius: 22)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
        .compositingGroup()              // prevent clip artifacts with rounded cards
        .drawingGroup(opaque: false)     // render in offscreen buffer for better blending
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
        .contentShape(Circle())
    }
}

// MARK: - Color mixing helper (kept for parity with other files; unused here but harmless)

private extension Color {
    func mix(with other: Color, amount: CGFloat) -> Color {
        let a = max(0, min(1, amount))
        #if canImport(UIKit)
        let ui1 = UIColor(self), ui2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1c: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2c: CGFloat = 0
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1c)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2c)
        return Color(
            red:     r1 + (r2 - r1) * a,
            green:   g1 + (g2 - g1) * a,
            blue:    b1 + (b2 - b1) * a,
            opacity: a1c + (a2c - a1c) * a
        )
        #else
        return self
        #endif
    }
}
