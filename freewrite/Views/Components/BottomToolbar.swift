//
//  BottomToolbar.swift
//  Flowstate
//
//  Bottom toolbar with font selection, timer, and utility buttons
//

import SwiftUI

struct BottomToolbar: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: EditorViewModel

    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let textColor = appState.colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
        let textHoverColor = appState.colorScheme == .light ? Color.black : Color.white

        HStack {
            // Font buttons (left side)
            fontButtons(textColor: textColor, textHoverColor: textHoverColor)

            Spacer()

            // Utility buttons (right side)
            utilityButtons(textColor: textColor, textHoverColor: textHoverColor)
        }
        .padding()
        .background(Color(appState.colorScheme == .light ? .white : .black))
        .opacity(viewModel.bottomNavOpacity)
        .onHover { hovering in
            viewModel.isHoveringBottomNav = hovering
            if hovering {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.bottomNavOpacity = 1.0
                }
            } else if appState.timerIsRunning {
                withAnimation(.easeIn(duration: 1.0)) {
                    viewModel.bottomNavOpacity = 0.0
                }
            }
        }
        .onReceive(timer) { _ in
            appState.tickTimer()
        }
    }

    // MARK: - Font Buttons

    @ViewBuilder
    private func fontButtons(textColor: Color, textHoverColor: Color) -> some View {
        HStack(spacing: 8) {
            // Font size
            Button("\(Int(appState.fontSize))px") {
                cycleFontSize()
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isHoveringSize ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringSize = hovering
                updateCursor(hovering: hovering)
            }

            separator

            // Lato
            fontButton("Lato", fontName: "Lato-Regular", textColor: textColor, textHoverColor: textHoverColor)
            separator
            fontButton("Arial", fontName: "Arial", textColor: textColor, textHoverColor: textHoverColor)
            separator
            fontButton("System", fontName: ".AppleSystemUIFont", textColor: textColor, textHoverColor: textHoverColor)
            separator
            fontButton("Serif", fontName: "Times New Roman", textColor: textColor, textHoverColor: textHoverColor)
            separator

            // Random font
            Button(randomButtonTitle) {
                selectRandomFont()
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.hoveredFont == "Random" ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.hoveredFont = hovering ? "Random" : nil
                updateCursor(hovering: hovering)
            }
        }
        .padding(8)
        .cornerRadius(6)
    }

    // MARK: - Utility Buttons

    @ViewBuilder
    private func utilityButtons(textColor: Color, textHoverColor: Color) -> some View {
        HStack(spacing: 8) {
            // Timer
            timerButton(textColor: textColor, textHoverColor: textHoverColor)
            separator

            // Chat
            chatButton(textColor: textColor, textHoverColor: textHoverColor)
            separator

            // Backspace toggle
            Button(viewModel.backspaceDisabled ? "Backspace is Off" : "Backspace is On") {
                viewModel.backspaceDisabled.toggle()
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isHoveringBackspaceToggle ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringBackspaceToggle = hovering
                updateCursor(hovering: hovering)
            }
            separator

            // Fullscreen
            Button(appState.isFullscreen ? "Minimize" : "Fullscreen") {
                viewModel.toggleFullscreen()
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isHoveringFullscreen ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringFullscreen = hovering
                updateCursor(hovering: hovering)
            }
            separator

            // New Entry
            Button("New Entry") {
                viewModel.createNewNote()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(viewModel.isHoveringNewEntry ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringNewEntry = hovering
                updateCursor(hovering: hovering)
            }
            separator

            // Theme toggle
            Button {
                appState.toggleTheme()
            } label: {
                Image(systemName: appState.colorScheme == .light ? "moon.fill" : "sun.max.fill")
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isHoveringThemeToggle ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringThemeToggle = hovering
                updateCursor(hovering: hovering)
            }
            separator

            // History (sidebar toggle)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showingSidebar.toggle()
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.isHoveringClock ? textHoverColor : textColor)
            .onHover { hovering in
                viewModel.isHoveringClock = hovering
                updateCursor(hovering: hovering)
            }
        }
        .padding(8)
        .cornerRadius(6)
    }

    // MARK: - Timer Button

    @ViewBuilder
    private func timerButton(textColor: Color, textHoverColor: Color) -> some View {
        let timerColor: Color = {
            if appState.timerIsRunning {
                return viewModel.isHoveringTimer ? textHoverColor : .gray.opacity(0.8)
            } else {
                return viewModel.isHoveringTimer ? textHoverColor : textColor
            }
        }()

        Button(appState.timerButtonTitle) {
            appState.toggleTimer()
        }
        .buttonStyle(.plain)
        .foregroundColor(timerColor)
        .onHover { hovering in
            viewModel.isHoveringTimer = hovering
            updateCursor(hovering: hovering)
        }
        .onAppear {
            setupScrollWheelMonitor()
        }
    }

    // MARK: - Chat Button

    @ViewBuilder
    private func chatButton(textColor: Color, textHoverColor: Color) -> some View {
        Button("Chat") {
            viewModel.showingChatMenu = true
            viewModel.didCopyPrompt = false
        }
        .buttonStyle(.plain)
        .foregroundColor(viewModel.isHoveringChat ? textHoverColor : textColor)
        .onHover { hovering in
            viewModel.isHoveringChat = hovering
            updateCursor(hovering: hovering)
        }
        .popover(isPresented: $viewModel.showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
            chatPopoverContent(textColor: textColor)
        }
    }

    @ViewBuilder
    private func chatPopoverContent(textColor: Color) -> some View {
        let backgroundColor = appState.colorScheme == .light ?
            Color(NSColor.controlBackgroundColor) :
            Color(NSColor.darkGray)
        let popoverTextColor = appState.colorScheme == .light ? Color.primary : Color.white

        VStack(spacing: 0) {
            if viewModel.isTextTooLongForUrl {
                longTextMessage(popoverTextColor: popoverTextColor)
            } else if viewModel.isWelcomeEntry {
                Text("Yo. Sorry, you can't chat with the guide lol. Please write your own entry.")
                    .font(.system(size: 14))
                    .foregroundColor(popoverTextColor)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else if viewModel.isTextTooShort {
                Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                    .font(.system(size: 14))
                    .foregroundColor(popoverTextColor)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                normalChatOptions(popoverTextColor: popoverTextColor)
            }
        }
        .frame(minWidth: 120, maxWidth: 250)
        .background(backgroundColor)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        .onChange(of: viewModel.showingChatMenu) { newValue in
            if !newValue {
                viewModel.didCopyPrompt = false
            }
        }
    }

    @ViewBuilder
    private func longTextMessage(popoverTextColor: Color) -> some View {
        Text("Hey, your entry is quite long. You'll need to manually copy the prompt by clicking 'Copy Prompt' below and then paste it into AI of your choice (ex. ChatGPT). The prompt includes your entry as well. So just copy paste and go! See what the AI says.")
            .font(.system(size: 14))
            .foregroundColor(popoverTextColor)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

        Divider()

        copyPromptButton(popoverTextColor: popoverTextColor)
    }

    @ViewBuilder
    private func normalChatOptions(popoverTextColor: Color) -> some View {
        Button {
            viewModel.showingChatMenu = false
            viewModel.openChatGPT()
        } label: {
            Text("ChatGPT")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundColor(popoverTextColor)
        .onHover { hovering in updateCursor(hovering: hovering) }

        Divider()

        Button {
            viewModel.showingChatMenu = false
            viewModel.openClaude()
        } label: {
            Text("Claude")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundColor(popoverTextColor)
        .onHover { hovering in updateCursor(hovering: hovering) }

        Divider()

        copyPromptButton(popoverTextColor: popoverTextColor)
    }

    @ViewBuilder
    private func copyPromptButton(popoverTextColor: Color) -> some View {
        Button {
            viewModel.copyPromptToClipboard()
        } label: {
            Text(viewModel.didCopyPrompt ? "Copied!" : "Copy Prompt")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundColor(popoverTextColor)
        .onHover { hovering in updateCursor(hovering: hovering) }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fontButton(_ title: String, fontName: String, textColor: Color, textHoverColor: Color) -> some View {
        Button(title) {
            appState.selectedFont = fontName
            appState.currentRandomFont = ""
        }
        .buttonStyle(.plain)
        .foregroundColor(viewModel.hoveredFont == title ? textHoverColor : textColor)
        .onHover { hovering in
            viewModel.hoveredFont = hovering ? title : nil
            updateCursor(hovering: hovering)
        }
    }

    private var separator: some View {
        Text("•").foregroundColor(.gray)
    }

    private var randomButtonTitle: String {
        appState.currentRandomFont.isEmpty ? "Random" : "Random [\(appState.currentRandomFont)]"
    }

    private func cycleFontSize() {
        if let currentIndex = appState.fontSizes.firstIndex(of: CGFloat(appState.fontSize)) {
            let nextIndex = (currentIndex + 1) % appState.fontSizes.count
            appState.fontSize = Double(appState.fontSizes[nextIndex])
        }
    }

    private func selectRandomFont() {
        if let randomFont = appState.availableFonts.randomElement() {
            appState.selectedFont = randomFont
            appState.currentRandomFont = randomFont
        }
    }

    private func updateCursor(hovering: Bool) {
        if hovering {
            NSCursor.pointingHand.push()
        } else {
            NSCursor.pop()
        }
    }

    private func setupScrollWheelMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if viewModel.isHoveringTimer {
                let scrollBuffer = event.deltaY * 0.25

                if abs(scrollBuffer) >= 0.1 {
                    let currentMinutes = appState.timeRemaining / 60
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    let direction = -scrollBuffer > 0 ? 5 : -5
                    let newMinutes = currentMinutes + Int(direction)
                    let roundedMinutes = (newMinutes / 5) * 5
                    let newTime = roundedMinutes * 60
                    appState.timeRemaining = min(max(newTime, 0), 2700)
                }
            }
            return event
        }
    }
}
