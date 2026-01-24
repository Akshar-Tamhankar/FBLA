
// FBLA/Setup/Onboarding.swift
// Swift 6 • iOS 17+
//
///  Full onboarding flow with:
///  - Accessibility toggles
///  - Name & email (validated)
///  - Notification permission + live toggles
///  - Optional age, school year, chapter code (validated ###-###)
///  - Appearance preference (live preview)
///
///  Persists into SwiftData `Profile` and marks `didCompleteSetup` on finish.
///
import SwiftUI
import SwiftData

/// A multi-step onboarding flow collecting profile details and preferences.
struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    // Step state (0…7)
    @State private var step: Int = 0

    // Identity
    @State private var fullName: String = ""
    @State private var email: String = ""

    // Notifications
    @State private var pushState: Notifications.AuthorizationState = .notDetermined

    // Other inputs
    @State private var ageString: String = ""
    @State private var schoolYear: SchoolYear = .other
    @State private var chapterCode: String = ""
    @State private var appearance: AppearancePreference = .system

    // Accessibility
    @State private var a11yLargeText: Bool = false
    @State private var a11yHighContrast: Bool = false
    @State private var a11yReduceMotion: Bool = false

    // Focus
    @FocusState private var textFieldFocused: Bool

    private var profile: Profile? { profiles.first }

    /// Live appearance preview while selecting mode.
    private var temporaryColorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(step), total: 7)
                .tint(.accentColor)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Steps
            TabView(selection: $step) {
                a11yStep.tag(0)
                nameStep.tag(1)
                emailStep.tag(2)
                pushStep.tag(3)
                ageStep.tag(4)
                yearStep.tag(5)
                chapterStep.tag(6)
                appearanceStep.tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: step)

            // Footer
            HStack {
                if step > 0 {
                    Button("Back") { withAnimation { step -= 1 } }
                        .buttonStyle(.bordered)
                } else { Spacer().frame(width: 0) }

                Spacer()

                Button(primaryButtonTitle) {
                    if step < 7 {
                        persistPartial()
                        withAnimation { step += 1 }
                    } else {
                        finish()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isCurrentStepValid)
            }
            .padding(16)
        }
        .preferredColorScheme(temporaryColorScheme)
        .onAppear(perform: ensureProfileExistsIfNeeded)
        .task {
            await refreshPushState()
            loadFromProfile()
        }
    }
}

// MARK: Steps

private extension OnboardingFlowView {
    var a11yStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Accessibility").font(.title2.bold())
                Text("Set what makes the app easier to use. You can change these anytime in Profile.")
                    .font(.subheadline).foregroundColor(.secondary)
                Toggle("Larger text", isOn: $a11yLargeText)
                Toggle("High contrast", isOn: $a11yHighContrast)
                Toggle("Reduce motion", isOn: $a11yReduceMotion)
            }
        }
        .padding(16)
    }

    var nameStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Name").font(.title2.bold())
                TextField("Full name", text: $fullName)
                    .textInputAutocapitalization(.words)
                    .focused($textFieldFocused)
            }
        }
        .padding(16)
    }

    var emailStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Email").font(.title2.bold())
                TextField("you@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .focused($textFieldFocused)
                if !email.isEmpty && !isValidEmail(email) {
                    Text("Please enter a valid email address.").font(.caption).foregroundColor(.red)
                }
                Text("We’ll use your email for chapter communication. You can update this later in Profile.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
    }

    var pushStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notifications").font(.title2.bold())
                switch pushState {
                case .granted:
                    Label("Notifications are enabled", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                case .denied:
                    Label("Notifications are turned off", systemImage: "xmark.circle").foregroundColor(.red)
                    Button("Open Settings") { Notifications.shared.openSystemSettings() }.buttonStyle(.bordered)
                case .notDetermined:
                    Text("Get reminders about events, practices, and chapter announcements.")
                }
                if pushState != .granted {
                    Button("Enable Notifications") { Task { await requestNotifications() } }
                        .buttonStyle(.borderedProminent)
                }
                Toggle("Announcements", isOn: Binding(
                    get: { profile?.notifyAnnouncements ?? true },
                    set: { profile?.notifyAnnouncements = $0; try? modelContext.save() }
                ))
                Toggle("Updates", isOn: Binding(
                    get: { profile?.notifyUpdates ?? true },
                    set: { profile?.notifyUpdates = $0; try? modelContext.save() }
                ))
            }
        }
        .padding(16)
    }

    var ageStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Age").font(.title2.bold())
                TextField("Age (optional)", text: $ageString)
                    .keyboardType(.numberPad)
                    .focused($textFieldFocused)
                Text("You can leave this blank.").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
    }

    var yearStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("School Year").font(.title2.bold())
                Picker("Year", selection: $schoolYear) {
                    ForEach(SchoolYear.allCases, id: \.self) { y in Text(y.label).tag(y) }
                }
                .pickerStyle(.inline)
            }
        }
        .padding(16)
    }

    var chapterStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("FBLA Chapter Code").font(.title2.bold())
                TextField("XXX-XXX", text: $chapterCode)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
                    .focused($textFieldFocused)
                Text("Enter your 6‑digit code with a dash (e.g., 123‑456). Test code: 000‑000")
                    .font(.caption).foregroundColor(.secondary)
                if !chapterCode.isEmpty && !isValidChapterCode(chapterCode) {
                    Text("Code must match the format 000-000.").font(.caption).foregroundColor(.red)
                }
            }
        }
        .padding(16)
    }

    var appearanceStep: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance").font(.title2.bold())
                Picker("Mode", selection: $appearance) {
                    Text("Use System").tag(AppearancePreference.system)
                    Text("Light").tag(AppearancePreference.light)
                    Text("Dark").tag(AppearancePreference.dark)
                }
                .pickerStyle(.segmented)
                Text("You can change this later in Profile.").font(.caption).foregroundColor(.secondary)
                Divider().padding(.vertical, 4)
                HStack {
                    Spacer()
                    Button("Finish") { finish() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isCurrentStepValid)
                    Spacer()
                }
            }
        }
        .padding(16)
    }
}

// MARK: Validation

private extension OnboardingFlowView {
    var isCurrentStepValid: Bool {
        switch step {
        case 0: return true
        case 1: return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return isValidEmail(email)
        case 3: return true
        case 4: return isAgeValid(ageString)
        case 5: return true
        case 6: return isValidChapterCode(chapterCode)
        case 7: return true
        default: return true
        }
    }

    var primaryButtonTitle: String { step < 7 ? "Next" : "Finish" }

    func isAgeValid(_ s: String) -> Bool {
        guard !s.isEmpty else { return true }
        return Int(s).map { (0...120).contains($0) } ?? false
    }

    func isValidChapterCode(_ s: String) -> Bool {
        let pattern = #"^\d{3}-\d{3}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#
        return s.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

// MARK: Persistence

private extension OnboardingFlowView {
    func ensureProfileExistsIfNeeded() {
        if profiles.isEmpty {
            let p = Profile.defaultProfile()
            modelContext.insert(p)
            try? modelContext.save()
        }
    }

    func loadFromProfile() {
        guard let p = profile else { return }
        fullName = p.fullName
        email = p.email
        ageString = p.age.map(String.init) ?? ""
        schoolYear = p.schoolYear
        chapterCode = p.chapterCode
        appearance = p.preferredAppearance
        a11yLargeText = p.a11yLargeText
        a11yHighContrast = p.a11yHighContrast
        a11yReduceMotion = p.a11yReduceMotion
    }

    func persistPartial() {
        guard let p = profile else { return }
        p.fullName = fullName
        if isValidEmail(email) { p.email = email }
        if isAgeValid(ageString), let v = Int(ageString) { p.age = v } else { p.age = nil }
        p.schoolYear = schoolYear
        if isValidChapterCode(chapterCode) { p.chapterCode = chapterCode }
        p.preferredAppearance = appearance
        p.a11yLargeText = a11yLargeText
        p.a11yHighContrast = a11yHighContrast
        p.a11yReduceMotion = a11yReduceMotion
        try? modelContext.save()
    }

    @MainActor
    func finish() {
        textFieldFocused = false
        persistPartial()
        guard let p = profile else { return }
        p.didCompleteSetup = true
        try? modelContext.save()
    }
}

// MARK: Notifications

private extension OnboardingFlowView {
    func refreshPushState() async {
        let state = await Notifications.shared.currentAuthorizationState()
        pushState = state
        if let p = profile {
            p.pushPermissionGranted = (state == .granted)
            try? modelContext.save()
        }
    }

    func requestNotifications() async {
        let state = await Notifications.shared.requestAuthorizationAndRegister()
        await MainActor.run {
            self.pushState = state
            if let p = profile {
                p.pushPermissionGranted = (state == .granted)
                try? modelContext.save()
            }
        }
    }
}

