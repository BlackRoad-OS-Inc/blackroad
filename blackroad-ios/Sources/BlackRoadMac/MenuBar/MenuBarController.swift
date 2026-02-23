import AppKit
import SwiftUI
import Combine

// ── Menu bar controller ───────────────────────────────────────
// Shows ⚡ in the status bar. Click → popover with:
//   • Live agent roster
//   • Quick chat
//   • Deploy buttons
//   • Tier health

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var health: MacHealthService
    private var cancellables = Set<AnyCancellable>()

    init(health: MacHealthService) {
        self.health = health
        super.init()
        setup()
    }

    private func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = menuBarIcon(tier: health.topTier)
            button.imagePosition = .imageLeft
            button.title = " BlackRoad"
            button.font = .systemFont(ofSize: 12, weight: .semibold)
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Update icon when tier changes
        health.$topTier
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tier in
                self?.statusItem.button?.image = self?.menuBarIcon(tier: tier)
                self?.statusItem.button?.title = " \(tier)"
            }
            .store(in: &cancellables)

        // Build popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopover(health: health)
                .preferredColorScheme(.dark)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func menuBarIcon(tier: String) -> NSImage? {
        let color: NSColor = switch tier {
        case "Pi Fleet":         .systemGreen
        case "DigitalOcean":     .systemOrange
        case "CF Pages", "GitHub Pages": .systemBlue
        case "All Down":         .systemRed
        default:                 .systemGray
        }
        let img = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "BlackRoad")
        img?.isTemplate = false
        let colored = img?.withTintColor(color)
        return colored
    }
}

// ── Menu bar popover content (SwiftUI) ───────────────────────
struct MenuBarPopover: View {
    @ObservedObject var health: MacHealthService
    @StateObject private var dispatch = MacDispatchService()
    @State private var tab: PopTab = .agents

    enum PopTab { case agents, deploy, status }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────
            HStack {
                Text("⚡ BlackRoad")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .pink, .purple, .blue],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
                // Live tier badge
                Text(health.topTier)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(tierColor(health.topTier).opacity(0.2))
                    .foregroundStyle(tierColor(health.topTier))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            // ── Tab bar ───────────────────────────────────────
            HStack(spacing: 0) {
                PopTabBtn(label: "Agents", icon: "cpu.fill",  active: tab == .agents) { tab = .agents }
                PopTabBtn(label: "Deploy", icon: "bolt.fill", active: tab == .deploy) { tab = .deploy }
                PopTabBtn(label: "Status", icon: "antenna.radiowaves.left.and.right",
                          active: tab == .status) { tab = .status }
            }
            .padding(6)

            Divider()

            // ── Content ───────────────────────────────────────
            Group {
                switch tab {
                case .agents: AgentRosterMini(agents: MacAgent.roster)
                case .deploy: DeployMini(dispatch: dispatch)
                case .status: TierStatusMini(tiers: health.tiers)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 360, height: 520)
    }

    private func tierColor(_ t: String) -> Color {
        switch t {
        case "Pi Fleet":     return .green
        case "DigitalOcean": return .orange
        default:             return .blue
        }
    }
}

// ── Mini sub-views ────────────────────────────────────────────
private struct PopTabBtn: View {
    let label: String; let icon: String; let active: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(active ? Color.pink.opacity(0.15) : .clear)
                .foregroundStyle(active ? .pink : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct AgentRosterMini: View {
    let agents: [MacAgent]
    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(agents) { agent in
                    HStack(spacing: 10) {
                        Circle().fill(agent.color.opacity(0.2)).frame(width: 28, height: 28)
                            .overlay(Text(agent.emoji).font(.system(size: 13)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(agent.name).font(.system(size: 12, weight: .semibold))
                            Text(agent.model).font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle().fill(agent.isOnline ? Color.green : .gray).frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 10)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct DeployMini: View {
    @ObservedObject var dispatch: MacDispatchService
    let actions = [
        ("Deploy Pi Fleet", "bolt.fill", Color.pink),
        ("Restart Agents",  "arrow.clockwise", Color.orange),
        ("Reload nginx",    "server.rack", Color.blue),
    ]
    var body: some View {
        VStack(spacing: 8) {
            ForEach(actions, id: \.0) { action in
                Button {
                    Task { await dispatch.trigger(action.0) }
                } label: {
                    Label(action.0, systemImage: action.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(action.2.opacity(0.1))
                        .foregroundStyle(action.2)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(dispatch.isDispatching)
            }
            if let result = dispatch.lastResult {
                Text(result).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            Spacer()
        }
        .padding(12)
    }
}

private struct TierStatusMini: View {
    let tiers: [MacTier]
    var body: some View {
        VStack(spacing: 6) {
            ForEach(tiers) { tier in
                HStack(spacing: 10) {
                    Text("\(tier.tier)").font(.system(size: 11, weight: .black, design: .monospaced))
                        .frame(width: 18)
                        .foregroundStyle(.secondary)
                    Text(tier.label).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Circle().fill(tier.up ? Color.green : .red).frame(width: 8, height: 8)
                        .shadow(color: tier.up ? .green : .clear, radius: 3)
                    Text(tier.up ? "UP" : "DOWN").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tier.up ? .green : .red)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}
