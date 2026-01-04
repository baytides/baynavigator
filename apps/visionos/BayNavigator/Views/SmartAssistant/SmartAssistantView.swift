import SwiftUI

/// Smart Assistant chat interface for AI-powered program discovery
struct SmartAssistantView: View {
    @State private var viewModel = SmartAssistantViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var onProgramSelected: ((AIProgram) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    onProgramTap: { program in
                                        onProgramSelected?(program)
                                    }
                                )
                                .id(message.id)
                            }

                            if viewModel.isLoading {
                                LoadingIndicator()
                                    .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isLoading) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Quick prompts (show only at start)
                if viewModel.messages.count == 1 {
                    QuickPromptsSection(
                        prompts: viewModel.quickPrompts,
                        onSelect: { prompt in
                            Task {
                                await viewModel.sendMessage(prompt)
                            }
                        }
                    )
                }

                // Input area
                InputSection(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
            }
            .navigationTitle("Smart Assistant")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearConversation()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .alert(
                viewModel.detectedCrisisType == .emergency ? "Emergency Resources" : "Crisis Support Available",
                isPresented: $viewModel.showCrisisAlert
            ) {
                if viewModel.detectedCrisisType == .emergency {
                    Button("Call 911", role: .destructive) {
                        if let url = URL(string: "tel://911") {
                            openURL(url)
                        }
                    }
                } else {
                    Button("Call 988 Crisis Lifeline") {
                        if let url = URL(string: "tel://988") {
                            openURL(url)
                        }
                    }
                    Button("Text HOME to 741741") {
                        if let url = URL(string: "sms:741741&body=HOME") {
                            openURL(url)
                        }
                    }
                }
                Button("Continue searching", role: .cancel) {}
            } message: {
                if viewModel.detectedCrisisType == .emergency {
                    Text("If you or someone else is in immediate danger, please call 911.")
                } else {
                    Text("If you're experiencing a mental health crisis, help is available 24/7.")
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isLoading {
                proxy.scrollTo("loading", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    var onProgramTap: ((AIProgram) -> Void)?

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(backgroundColor)
                    }
                    .foregroundStyle(message.role == .user ? .white : .primary)

                // Program cards
                if let programs = message.programs, !programs.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(programs.prefix(3)) { program in
                            MiniProgramCard(program: program)
                                .onTapGesture {
                                    onProgramTap?(program)
                                }
                        }

                        if programs.count > 3 {
                            Text("+\(programs.count - 3) more programs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    private var backgroundColor: Color {
        if message.role == .user {
            return .appPrimary
        } else if message.isError {
            return .red.opacity(0.15)
        } else {
            return .secondary.opacity(0.1)
        }
    }
}

// MARK: - Mini Program Card

private struct MiniProgramCard: View {
    let program: AIProgram

    private var categoryColor: Color {
        Color.categoryColor(for: program.category)
    }

    private var categoryIcon: String {
        switch program.category.lowercased() {
        case "food", "food assistance":
            return "fork.knife"
        case "health", "healthcare", "medical":
            return "heart.text.square.fill"
        case "recreation", "activities", "entertainment":
            return "ticket.fill"
        case "community", "community services", "social services":
            return "person.3.fill"
        case "education", "learning", "training":
            return "graduationcap.fill"
        case "finance", "financial", "financial assistance":
            return "dollarsign.circle.fill"
        case "transportation", "transit":
            return "car.fill"
        case "technology", "tech", "internet":
            return "laptopcomputer"
        case "legal", "legal aid":
            return "scale.3d"
        case "housing", "shelter":
            return "house.fill"
        case "utilities", "energy":
            return "bolt.fill"
        case "childcare", "childcare assistance":
            return "figure.and.child.holdinghands"
        default:
            return "info.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: categoryIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(categoryColor)
            }

            // Program info
            VStack(alignment: .leading, spacing: 2) {
                Text(program.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(program.category)
                    .font(.caption)
                    .foregroundStyle(categoryColor)

                if let description = program.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.highlight)
    }
}

// MARK: - Quick Prompts Section

private struct QuickPromptsSection: View {
    let prompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}

// MARK: - Input Section

private struct InputSection: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask about programs...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .lineLimit(1...4)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading {
                        onSend()
                    }
                }

            Button {
                onSend()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(canSend ? .appPrimary : .secondary)
            }
            .disabled(!canSend)
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Loading Indicator

private struct LoadingIndicator: View {
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(animationOpacity(for: index))
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.secondary.opacity(0.1))
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }

    private func animationOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
        return 0.4 + phase * 0.6
    }
}

// MARK: - Preview

#Preview(windowStyle: .automatic) {
    SmartAssistantView()
}
