import SwiftUI
import SafariServices

struct ChapterSocialScreen: View {
    // TODO: Replace with your chapter links
    private let instagramURL = URL(string: "https://www.instagram.com/YOURCHAPTER/")!
    private let xURL = URL(string: "https://x.com/YOURCHAPTER")!
    private let youtubeURL = URL(string: "https://www.youtube.com/@YOURCHAPTER")!

    @State private var selected = 0
    @State private var openURL: IdentifiableURL?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SectionTitle(title: "Chapter Social")

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stay connected with our chapter’s updates, photos, and announcements.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Channel", selection: $selected) {
                            Text("Instagram").tag(0)
                            Text("X").tag(1)
                            Text("YouTube").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions").font(.headline)

                        HStack(spacing: 12) {
                            Button {
                                openURL = IdentifiableURL(url: currentURL)
                            } label: {
                                Label("Open", systemImage: "safari")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            ShareLink(item: currentURL) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // “Feed cards” (simple, effective, and judges like it)
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlights").font(.headline)
                        HighlightRow(title: "Upcoming Meeting", subtitle: "Tap to view latest post/story link", url: instagramURL)
                        Divider().opacity(0.2)
                        HighlightRow(title: "Competition Updates", subtitle: "Deadlines, reminders, check-ins", url: xURL)
                        Divider().opacity(0.2)
                        HighlightRow(title: "Chapter Videos", subtitle: "Recaps, officer intros, events", url: youtubeURL)
                    }
                }
            }
            .padding(16)
        }
        .sheet(item: $openURL) { item in
            SafariView(url: item.url)
        }
    }

    private var currentURL: URL {
        switch selected {
        case 0: return instagramURL
        case 1: return xURL
        default: return youtubeURL
        }
    }
}

private struct HighlightRow: View {
    let title: String
    let subtitle: String
    let url: URL

    var body: some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// Safari sheet (in-app browser)
private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
