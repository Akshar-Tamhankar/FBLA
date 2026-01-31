import SwiftUI

struct SocialLink: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let url: URL
}

struct SocialLinksView: View {
    private let links: [SocialLink] = [
            // Chapter
            .init(title: "Our Chapter Instagram", systemImage: "person.3",
                  url: URL(string: "https://www.instagram.com/YOURCHAPTER/")!),

            // National
            .init(title: "FBLA National Instagram", systemImage: "camera",
                  url: URL(string: "https://www.instagram.com/fbla_pbl/")!),

            .init(title: "X (Twitter)", systemImage: "bird",
                  url: URL(string: "https://x.com/FBLA_PBL")!),

            .init(title: "YouTube", systemImage: "play.rectangle",
                  url: URL(string: "https://www.youtube.com/@FBLA-PBL")!),

            .init(title: "Website", systemImage: "globe",
                  url: URL(string: "https://www.fbla-pbl.org")!)
        ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social")
                .font(.headline)

            ForEach(links) { link in
                Link(destination: link.url) {
                    HStack(spacing: 12) {
                        Image(systemName: link.systemImage)
                            .frame(width: 24)
                        Text(link.title)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
