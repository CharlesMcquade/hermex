import SwiftUI

/// The two sides of a Hermes server's home (#709): the Bots inbox and the session list.
enum HermesHomeTab: String {
    case bots, sessions
}

/// What both sides of a Hermes server's home share: the server's name, which titles a pushed
/// screen's back button, the server's avatar in the header, and the switch between the sides.
struct HermesHome {
    let title: String
    let avatar: SessionsHeader.Avatar
    let tab: Binding<HermesHomeTab>
    /// The home's measured width, so both sides decide split-vs-stack the same way
    /// (`HermesHomeLayout.usesSplit`). nil until the first layout.
    var containerWidth: CGFloat? = nil
    /// Split layouts keep the bottom `[Bots | Sessions]` segment; on compact the home
    /// drawer (hamburger in the header) owns the switch instead, so the segment goes.
    var showsTabSwitch: Bool = true
}

/// The Hermes home's bar chrome (#709), the same on both sides: no top bar, since each side's
/// list leads with the session list's header (`SessionsHeader`), and a bottom bar of
/// `(filter) [Bots | Sessions] (new chat)` whose ends each side fills. The title names a pushed
/// screen's back button, and stays inline so a pushed screen such as Tasks keeps the one-line bar.
/// On iOS 26 the bar's glass pills float over the list: the system's bottom scroll edge effect
/// read as a solid band behind them, so it is hidden.
struct HermesHomeChrome<Filter: View, NewChat: View>: ViewModifier {
    let home: HermesHome
    @ViewBuilder let filter: Filter
    @ViewBuilder let newChat: NewChat

    func body(content: Content) -> some View {
        content
            .modifier(HiddenBottomScrollEdge())
            .navigationTitle(home.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .bottomBar) { filter }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    if home.showsTabSwitch {
                        // The segmented control is its own pill; a glass one around it would double it.
                        ToolbarItem(placement: .bottomBar) { HermesHomeSwitch(tab: home.tab) }
                            .sharedBackgroundVisibility(.hidden)
                        ToolbarSpacer(.flexible, placement: .bottomBar)
                    }
                } else if home.showsTabSwitch {
                    ToolbarItem(placement: .bottomBar) { HermesHomeSwitch(tab: home.tab) }
                }
                ToolbarItem(placement: .bottomBar) { newChat }
            }
    }
}

private struct HiddenBottomScrollEdge: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            content
        }
    }
}

/// `[Bots | Sessions]`. It keeps a system bar's size at accessibility text sizes; a long press
/// shows the Large Content Viewer instead.
private struct HermesHomeSwitch: View {
    @Binding var tab: HermesHomeTab

    var body: some View {
        // The segments name themselves; the picker needs no label of its own.
        Picker(selection: $tab) {
            Text("Bots").tag(HermesHomeTab.bots)
            Text("Sessions").tag(HermesHomeTab.sessions)
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        // A bare `.fixedSize()` hugs the longer label (#1344); the minimum gives both segments
        // room, and a longer translation still widens the switch instead of truncating.
        .frame(minWidth: 200)
        .fixedSize()
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityShowsLargeContentViewer()
    }
}

/// Drawer metrics. Outside the generic overlay type: Swift forbids static
/// stored properties on generic types.
private enum HomeDrawerMetrics {
    static let panelWidth: CGFloat = 312
    static let dismissDragDistance: CGFloat = 70
}

/// The compact home's slide-out menu: a leading panel over a dimming scrim.
/// Tap outside or swipe the panel left to close; the hamburger in the header
/// opens it. Split layouts never show it — their sidebar is already the menu.
struct HomeDrawerOverlay<Menu: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> Menu

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Negative while the user drags the panel left toward closed.
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            scrim
            panel
        }
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86), value: isOpen)
    }

    private var scrim: some View {
        Color.black
            .opacity(isOpen ? 0.4 : 0)
            .ignoresSafeArea()
            .onTapGesture(perform: close)
            .accessibilityHidden(true)
    }

    private var panel: some View {
        menu()
            .frame(width: HomeDrawerMetrics.panelWidth)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.thickMaterial, ignoresSafeAreaEdges: .vertical)
            .overlay(alignment: .trailing) {
                Color(.separator).opacity(0.5).frame(width: 0.5)
                    .ignoresSafeArea(.container, edges: .vertical)
            }
            .shadow(color: .black.opacity(0.22), radius: 16, x: 6)
            .offset(x: isOpen ? dragTranslation : -HomeDrawerMetrics.panelWidth - 28)
            .allowsHitTesting(isOpen)
            .gesture(swipeToClose)
            .accessibilityAction(.escape) { close() }
            .accessibilityHidden(!isOpen)
    }

    private var swipeToClose: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragTranslation = min(0, value.translation.width)
            }
            .onEnded { value in
                let dismissed = value.translation.width < -HomeDrawerMetrics.dismissDragDistance
                withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9)) {
                    dragTranslation = 0
                    if dismissed { isOpen = false }
                }
            }
    }

    private func close() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9)) {
            isOpen = false
        }
    }
}

/// One tappable destination row inside the home drawer.
struct HomeDrawerEntry: View {
    let title: String
    let systemImage: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.body.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.accentColor : Color.primary)
            } icon: {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                    .frame(width: 26)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
