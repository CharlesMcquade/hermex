import SwiftUI
import UIKit

extension View {
    /// A Settings page's list (#1252): inset grouped, titled inline under the index's large title.
    func settingsPage(_ title: String) -> some View {
        listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppSurfaceColor.groupedBackground.ignoresSafeArea())
            .listRowBackground(AppSurfaceColor.secondaryGroupedBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// A Settings row's title beside its gray glyph, with an optional note under the title for what
/// the row needs explained.
struct SettingsLabel: View {
    let title: String
    let systemImage: String
    var note: String?

    var body: some View {
        Label {
            if let note {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(title)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }
}

/// A row that opens a web page or iOS Settings, marked with an outward arrow.
struct SettingsExternalLink: View {
    let title: String
    let systemImage: String
    let destination: URL
    var accessibilityLabel: String?

    var body: some View {
        Link(destination: destination) {
            LabeledContent {
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            } label: {
                SettingsLabel(title: title, systemImage: systemImage)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

/// Small circular avatar (initials + per-server Header Logo Color) for server rows.
struct ServerAvatarBadge: View {
    let initials: String
    let colorHex: String
    var size: CGFloat = 32

    var body: some View {
        Text(initials)
            .font(AppFont.caption(weight: .semibold))
            .foregroundStyle(HeaderLogoColor.prefersDarkForeground(for: colorHex) ? Color.black : Color.white)
            .frame(width: size, height: size)
            .background(HeaderLogoColor.color(for: colorHex), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

struct SettingsStatusPill: View {
    let label: String
    var tint: Color = .secondary

    var body: some View {
        Text(label)
            .font(AppFont.caption(weight: .semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.12)))
    }
}

struct SettingsTextFieldRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure = false
    var submitLabel: SubmitLabel = .return
    /// Title above a full-width field at every text size, for values too long for the
    /// trailing field, such as a server address.
    var isStacked = false
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize || isStacked {
                VStack(alignment: .leading, spacing: 6) {
                    titleLabel
                    textField
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: 12) {
                    titleLabel

                    Spacer(minLength: 12)

                    textField
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 190)
                }
            }
        }
    }

    private var titleLabel: some View {
        Text(title)
            .font(AppFont.subheadline())
    }

    @ViewBuilder
    private var textField: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(AppFont.subheadline())
        .textInputAutocapitalization(autocapitalization)
        .autocorrectionDisabled()
        .keyboardType(keyboardType)
        .submitLabel(submitLabel)
        .onSubmit { onSubmit?() }
    }
}

/// The shared swatch-grid color picker. On the Appearance page it edits the
/// global app color (the Verity logotype and, optionally, primary actions);
/// the add/edit-server identity editor reuses it for a server's avatar color,
/// so the title and accessibility wording are parameterized.
struct HeaderLogoColorSettings: View {
    var title: String = String(localized: "App Color")
    var presetAccessibilityNoun: String = "app color"
    var presetAccessibilityHint: String = String(localized: "Updates the app color.")
    @Binding var selectedHex: String
    let customColor: Binding<Color>

    private var selectedColorName: String {
        HeaderLogoColor.displayName(for: selectedHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Text(selectedColorName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            HermesHeaderLogo(selectedColor: HeaderLogoColor.color(for: selectedHex))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .accessibilityHidden(true)

            HStack(spacing: 10) {
                ForEach(HeaderLogoColor.presets) { preset in
                    HeaderLogoColorPresetButton(
                        preset: preset,
                        isSelected: HeaderLogoColor.normalizedHex(selectedHex) == preset.hex,
                        accessibilityNoun: presetAccessibilityNoun,
                        accessibilityHint: presetAccessibilityHint
                    ) {
                        selectedHex = preset.hex
                    }
                }
            }

            ColorPicker("Custom", selection: customColor, supportsOpacity: false)
                .font(.subheadline)
        }
    }
}

private struct HeaderLogoColorPresetButton: View {
    let preset: HeaderLogoColorPreset
    let isSelected: Bool
    let accessibilityNoun: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(preset.color)
                    .overlay(Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(preset.hex == "#FFFFFF" ? .black : .white)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 34, height: 34)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(preset.name) \(accessibilityNoun)"))
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint(accessibilityHint)
    }
}
