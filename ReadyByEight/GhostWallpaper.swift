import SwiftUI

private struct GhostWallpaperDimmedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Nightstand keeps the same sky, but dims every layer together to save power.
    var ghostWallpaperDimmed: Bool {
        get { self[GhostWallpaperDimmedKey.self] }
        set { self[GhostWallpaperDimmedKey.self] = newValue }
    }
}

/// Six animated cosmic wallpaper themes plus an optional wallpaper from a web image URL.
enum CosmicTheme: String, CaseIterable, Identifiable {
    case lavenderNebula, midnightOcean, auroraDream, sunsetGalaxy, cosmicRose, stardustMint
    var id: String { rawValue }

    var title: String {
        switch self {
        case .lavenderNebula: return "Lavender Nebula"
        case .midnightOcean: return "Midnight Ocean"
        case .auroraDream: return "Aurora Dream"
        case .sunsetGalaxy: return "Sunset Galaxy"
        case .cosmicRose: return "Cosmic Rose"
        case .stardustMint: return "Stardust Mint"
        }
    }

    var colors: [Color] {
        switch self {
        case .lavenderNebula: return [Color(red: 0.09, green: 0.04, blue: 0.20), Color(red: 0.28, green: 0.15, blue: 0.50), Color(red: 0.55, green: 0.35, blue: 0.80)]
        case .midnightOcean: return [Color(red: 0.02, green: 0.04, blue: 0.12), Color(red: 0.05, green: 0.18, blue: 0.35), Color(red: 0.20, green: 0.45, blue: 0.70)]
        case .auroraDream: return [Color(red: 0.02, green: 0.10, blue: 0.14), Color(red: 0.08, green: 0.30, blue: 0.32), Color(red: 0.40, green: 0.30, blue: 0.65)]
        case .sunsetGalaxy: return [Color(red: 0.15, green: 0.03, blue: 0.10), Color(red: 0.45, green: 0.12, blue: 0.25), Color(red: 0.85, green: 0.40, blue: 0.35)]
        case .cosmicRose: return [Color(red: 0.12, green: 0.02, blue: 0.12), Color(red: 0.38, green: 0.10, blue: 0.32), Color(red: 0.75, green: 0.35, blue: 0.60)]
        case .stardustMint: return [Color(red: 0.03, green: 0.10, blue: 0.10), Color(red: 0.10, green: 0.28, blue: 0.28), Color(red: 0.35, green: 0.65, blue: 0.60)]
        }
    }

    static func from(_ raw: String) -> CosmicTheme { CosmicTheme(rawValue: raw) ?? .lavenderNebula }
}

enum WallpaperURL {
    /// Accepts only http(s) URLs with a host, so pasted text can't load other schemes.
    static func validated(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http", url.host != nil else { return nil }
        return url
    }
}

/// Moving live wallpaper: drifting nebula blobs and twinkling stars on one shared clock.
struct GhostLiveWallpaper: View {
    @AppStorage("wallpaperTheme") private var themeRaw = CosmicTheme.lavenderNebula.rawValue
    @AppStorage("wallpaperURL") private var urlText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.ghostWallpaperDimmed) private var dimmed

    var body: some View {
        let theme = CosmicTheme.from(themeRaw)
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: dimmed ? 0.25 : 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(colors: [theme.colors[0], theme.colors[1]], startPoint: .top, endPoint: .bottom)
                    if let url = WallpaperURL.validated(urlText) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill().opacity(0.55)
                        } placeholder: { Color.clear }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    }
                    ForEach(0..<3, id: \.self) { i in
                        let phase = Double(i) * 2.1
                        Circle()
                            .fill(theme.colors[(i % 2) + 1].opacity(0.45))
                            .frame(width: geo.size.width * 0.8)
                            .blur(radius: 60)
                            .offset(x: CGFloat(sin(t * 0.15 + phase)) * geo.size.width * 0.3,
                                    y: CGFloat(cos(t * 0.12 + phase)) * geo.size.height * 0.25)
                    }
                    ForEach(0..<28, id: \.self) { i in
                        let x = Double((i * 37) % 100) / 100.0
                        let y = Double((i * 61) % 100) / 100.0
                        Circle()
                            .fill(Color.white)
                            .frame(width: i.isMultiple(of: 3) ? 3 : 2)
                            .opacity(0.35 + 0.6 * abs(sin(t * 0.9 + Double(i))))
                            .position(x: x * geo.size.width, y: y * geo.size.height)
                    }
                    // Three slow shooting stars, sharing the same timeline as the mascot.
                    ForEach(0..<3, id: \.self) { i in
                        let cycle = (t * 0.075 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                        Capsule()
                            .fill(LinearGradient(colors: [.clear, .white.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 90, height: 2)
                            .rotationEffect(.degrees(22))
                            .opacity(sin(cycle * .pi) * 0.65)
                            .position(x: geo.size.width * (1.15 - cycle * 0.75),
                                      y: geo.size.height * (0.12 + Double(i) * 0.17 + cycle * 0.18))
                    }
                }
                .brightness(dimmed ? -0.12 : 0)
                .opacity(dimmed ? 0.24 : 1)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Theme picker and web wallpaper URL field (place inside Settings).
struct GhostWallpaperPicker: View {
    @AppStorage("wallpaperTheme") private var themeRaw = CosmicTheme.lavenderNebula.rawValue
    @AppStorage("wallpaperURL") private var urlText = ""
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live wallpaper").font(.headline).foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(CosmicTheme.allCases) { theme in
                    Button {
                        themeRaw = theme.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 56)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white, lineWidth: themeRaw == theme.rawValue ? 2 : 0))
                            Text(theme.title).font(.caption2).foregroundStyle(.white).lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.title)
                }
            }
            TextField("Paste an image URL (https://…)", text: $draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            HStack {
                Button("Use URL") {
                    if WallpaperURL.validated(draft) != nil { urlText = draft }
                }
                .disabled(WallpaperURL.validated(draft) == nil)
                Spacer()
                Button("Clear wallpaper") { urlText = ""; draft = "" }
                    .disabled(urlText.isEmpty)
            }
            .font(.subheadline.weight(.semibold))
        }
        .onAppear { draft = urlText }
    }
}
