import SwiftUI

struct AccuracyTrial: Identifiable {
    let id = UUID()
    var label: String
    var groundTruthInches: Double
    var scannedInches: Double

    var errorInches: Double { scannedInches - groundTruthInches }
    var absErrorInches: Double { abs(errorInches) }
}

struct AccuracyTestView: View {
    let scanStore: ScanStore

    private enum ScannedSource: String, CaseIterable, Identifiable {
        case lastScan = "Last Scan"
        case average = "Average"
        var id: Self { self }
    }

    @State private var trials: [AccuracyTrial] = []
    @State private var source: ScannedSource = .lastScan

    // Controls the decimal-pad keyboard; the "Done" toolbar button sets it
    // false to dismiss (the decimal pad has no Return key of its own).
    @FocusState private var keyboardActive: Bool

    // Tape-measure ground truth per dimension, in decimal inches. These are
    // deliberately NOT cleared after logging: the real closet doesn't change
    // between scans, so the user can rescan and just tap "Add Trials" again.
    @State private var widthGroundTruth = ""
    @State private var depthGroundTruth = ""
    @State private var heightGroundTruth = ""

    private var activeDimensions: ClosetDimensions? {
        switch source {
        case .lastScan: scanStore.lastDimensions
        case .average: scanStore.averagedDimensions
        }
    }

    /// Appended to trial labels so averaged trials are distinguishable in the log.
    private var sourceSuffix: String {
        source == .average ? " (avg of \(scanStore.scans.count) scans)" : ""
    }

    private var meanAbsError: Double {
        guard !trials.isEmpty else { return 0 }
        return trials.map(\.absErrorInches).reduce(0, +) / Double(trials.count)
    }

    private var maxError: Double {
        trials.map(\.absErrorInches).max() ?? 0
    }

    private var hasAnyGroundTruth: Bool {
        Double(widthGroundTruth) != nil || Double(depthGroundTruth) != nil || Double(heightGroundTruth) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                if let dims = activeDimensions {
                    sourceSection
                    logSection(dims)
                } else {
                    Section("Log Measurements") {
                        Text("No scan yet — complete a scan first and the app-measured values will be filled in automatically.")
                            .foregroundStyle(.secondary)
                    }
                }

                if !trials.isEmpty {
                    summarySection
                    trialsSection
                }
            }
            .navigationTitle("Accuracy Test")
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        keyboardActive = false
                    }
                }
            }
        }
    }

    private var sourceSection: some View {
        Section {
            Picker("Scanned value source", selection: $source) {
                ForEach(ScannedSource.allCases) { option in
                    Text(option == .average ? "Average (\(scanStore.scans.count))" : option.rawValue)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)

            if source == .average, scanStore.scans.count >= 2 {
                Text(String(format: "Scan-to-scan spread — W: %.3f\"  D: %.3f\"  H: %.3f\"",
                            scanStore.spreadInches(of: \.widthInches),
                            scanStore.spreadInches(of: \.depthInches),
                            scanStore.spreadInches(of: \.heightInches)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Clear Recorded Scans", role: .destructive) {
                scanStore.clearScans()
            }
        } header: {
            Text("Scanned Value Source")
        } footer: {
            Text("\(scanStore.scans.count) scan(s) recorded. Averaging repeated scans of the same closet reduces random sensor noise by roughly \u{221A}N (it cannot fix a systematic scale bias). Clear recorded scans before scanning a different space.")
        }
    }

    private func logSection(_ dims: ClosetDimensions) -> some View {
        Section {
            measurementRow("Width", groundTruth: $widthGroundTruth, scanned: dims.widthInches)
            measurementRow("Depth", groundTruth: $depthGroundTruth, scanned: dims.depthInches)
            measurementRow("Height", groundTruth: $heightGroundTruth, scanned: dims.heightInches)

            Button("Add Trials") {
                addTrials(dims)
            }
            .disabled(!hasAnyGroundTruth)
        } header: {
            Text("Log Measurements")
        } footer: {
            Text("Enter your tape-measure values in decimal inches (e.g. 81 for 6' 9\", 30.5 for 2' 6 1/2\"). App-scanned values are filled in automatically. Leave a field blank to skip that dimension. Width is the longer horizontal dimension, Depth the shorter.")
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            HStack {
                Text("Trials logged")
                Spacer()
                Text("\(trials.count)")
            }
            HStack {
                Text("Mean absolute error")
                Spacer()
                Text(String(format: "%.3f\" (%@)", meanAbsError, DimensionFormatter.feetInchesFraction(meanAbsError)))
            }
            HStack {
                Text("Max absolute error")
                Spacer()
                Text(String(format: "%.3f\"", maxError))
            }
            HStack {
                Text("Target (1/16\")")
                Spacer()
                Text(meanAbsError <= 0.0625 ? "✅ met" : "⚠️ not met")
                    .foregroundStyle(meanAbsError <= 0.0625 ? .green : .orange)
            }
        }
    }

    private var trialsSection: some View {
        Section("Trials") {
            ForEach(trials) { trial in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trial.label).font(.subheadline.bold())
                    Text(String(format: "Ground truth: %.3f\"   Scanned: %.3f\"   Error: %.3f\"",
                                trial.groundTruthInches, trial.scannedInches, trial.errorInches))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { trials.remove(atOffsets: $0) }
        }
    }

    private func measurementRow(_ name: String, groundTruth: Binding<String>, scanned: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                Spacer()
                Text(String(format: "App: %@ (%.3f\")", DimensionFormatter.feetInchesFraction(scanned), scanned))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField("Tape measure, inches", text: groundTruth)
                .keyboardType(.decimalPad)
                .focused($keyboardActive)
        }
    }

    private func addTrials(_ dims: ClosetDimensions) {
        keyboardActive = false
        if let gt = Double(widthGroundTruth) {
            trials.append(AccuracyTrial(label: "Width" + sourceSuffix, groundTruthInches: gt, scannedInches: dims.widthInches))
        }
        if let gt = Double(depthGroundTruth) {
            trials.append(AccuracyTrial(label: "Depth" + sourceSuffix, groundTruthInches: gt, scannedInches: dims.depthInches))
        }
        if let gt = Double(heightGroundTruth) {
            trials.append(AccuracyTrial(label: "Height" + sourceSuffix, groundTruthInches: gt, scannedInches: dims.heightInches))
        }
    }
}
