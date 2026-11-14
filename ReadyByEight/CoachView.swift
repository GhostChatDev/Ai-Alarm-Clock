import SwiftUI

// Semantic text colors preserve contrast; the accent is used on dark surfaces.
enum Theme {
    static let accent = Color(red: 0.76, green: 0.91, blue: 0.62)
    static let background = Color(red: 0.055, green: 0.065, blue: 0.075)
}

extension View {
    func card() -> some View {
        padding(18)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.07)))
    }
}

struct CoachView: View {
    @Environment(AppStore.self) private var store
    @State private var draft = ""
    @State private var clearing = false
    @FocusState private var composing: Bool
    private let prompts = ["Give me a challenge", "I’m running late", "I feel tired"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield").foregroundStyle(Theme.accent)
                    Text(store.coachName).font(.caption)
                    Spacer()
                }.foregroundStyle(.secondary).padding(.horizontal, 20).padding(.vertical, 12)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            if store.state.messages.isEmpty { welcome }
                            ForEach(store.state.messages) { message in
                                messageView(message)
                            }
                            if store.sending {
                                HStack {
                                    ProgressView().tint(Theme.accent)
                                    Text("Eight is thinking…").font(.caption).foregroundStyle(.secondary)
                                }.padding(.vertical, 8)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }.padding(20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: store.state.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: store.sending) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(prompts, id: \.self) { prompt in
                                Button(prompt) { send(prompt) }
                                    .font(.caption).buttonStyle(.bordered).tint(Theme.accent)
                                    .disabled(store.sending)
                            }
                        }
                    }
                    HStack(alignment: .bottom, spacing: 12) {
                        TextField("Message Eight", text: $draft, axis: .vertical)
                            .lineLimit(1...5).focused($composing)
                            .onChange(of: draft) { _, value in draft = String(value.prefix(2_000)) }
                            .padding(12).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                        Button {
                            let text = draft
                            draft = ""
                            composing = false
                            send(text)
                        } label: {
                            Image(systemName: "arrow.up").font(.headline)
                                .frame(width: 44, height: 44)
                                .background(Theme.accent, in: Circle()).foregroundStyle(.black)
                        }
                        .accessibilityLabel("Send message")
                        .disabled(store.sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text("Private on-device conversations. Eight can suggest, not set, reminders.")
                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                    .background(Theme.background)
            }
            .background(Theme.background)
            .navigationTitle("Eight").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear conversation", systemImage: "trash") { clearing = true }
                        .disabled(store.sending || store.state.messages.isEmpty)
                }
            }
            .confirmationDialog("Clear this conversation from this app?", isPresented: $clearing,
                                titleVisibility: .visible) {
                Button("Clear conversation", role: .destructive) { store.clearChat() }
            }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.accent)
            Text("A small start.\nA better morning.")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
            Text("I’m Eight, your morning coach. Ask for a gentle push, a two-minute challenge, or help simplifying a rushed morning.")
                .foregroundStyle(.secondary)
            Text("AI needs a compatible Apple Intelligence device with its model downloaded. Otherwise you’ll get clearly labeled, built-in guided replies. No account or API key required.")
                .font(.footnote).foregroundStyle(.secondary)
        }.padding(.vertical, 28)
    }

    private func messageView(_ message: CoachMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.isUser ? "YOU" : "EIGHT")
                    .font(.caption2.weight(.bold)).foregroundStyle(Theme.accent)
                Text(message.text).textSelection(.enabled).font(.body)
            }
            .padding(16)
            .background(message.isUser ? Theme.accent.opacity(0.12) : .white.opacity(0.055),
                        in: RoundedRectangle(cornerRadius: 20))
            if !message.isUser { Spacer(minLength: 32) }
        }
    }

    private func send(_ text: String) {
        Task { await store.send(text) }
    }
}
