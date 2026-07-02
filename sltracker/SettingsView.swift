//
//  SettingsView.swift
//  sltracker
//
//  App settings, opened from the gear on the home screen.
//

import SwiftUI

struct SettingsView: View {

    /// Shared widget settings (transit-mode filter, etc.)
    let settings: WidgetSettingsManager

    @Environment(\.dismiss) private var dismiss

    /// All transit modes, in canonical display order. Uses the shared
    /// `TransportMode` helper so labels/icons/colors match the rest of the app.
    private let allModes: [TransportMode] = [.metro, .tram, .bus, .train, .ship]

    /// Locally-edited set of enabled mode codes ("METRO", …). Seeded from the saved
    /// setting (or all modes when no filter is set). Persisted on dismiss.
    @State private var selectedModes: Set<String>

    init(settings: WidgetSettingsManager) {
        self.settings = settings
        let allCodes = ["METRO", "TRAM", "BUS", "TRAIN", "SHIP"]
        _selectedModes = State(initialValue: Set(settings.enabledModes ?? allCodes))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(allModes, id: \.rawValue) { mode in
                        Toggle(isOn: binding(for: mode.rawValue)) {
                            Label {
                                Text(mode.displayName)
                            } icon: {
                                Image(systemName: mode.icon)
                                    .foregroundStyle(mode.tint)
                            }
                        }
                    }
                } header: {
                    Text("Widget")
                } footer: {
                    Text("Choose which transit modes appear on the Home Screen widget. At least one must stay selected.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onDisappear(perform: commit)
    }

    /// A toggle binding that prevents deselecting the final remaining mode,
    /// so the widget can never be configured to show nothing.
    private func binding(for code: String) -> Binding<Bool> {
        Binding(
            get: { selectedModes.contains(code) },
            set: { isOn in
                if isOn {
                    selectedModes.insert(code)
                } else if selectedModes.count > 1 {
                    selectedModes.remove(code)
                }
            }
        )
    }

    /// Persist the selection. All modes selected ⇒ clear the filter (show all).
    private func commit() {
        if selectedModes.count == allModes.count {
            settings.setEnabledModes(nil)
        } else {
            // Store in canonical order for stable, predictable output.
            settings.setEnabledModes(allModes.map(\.rawValue).filter { selectedModes.contains($0) })
        }
    }
}

#Preview {
    SettingsView(settings: WidgetSettingsManager())
}
