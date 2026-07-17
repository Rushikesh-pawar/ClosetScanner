import SwiftUI
import SceneKit
import RoomPlan

struct EmptyRoomResultsView: View {
    let room: CapturedRoom

    private var dimensions: ClosetDimensions? {
        RoomDimensionCalculator.computeDimensions(from: room)
    }

    private var scene: SCNScene {
        StructuralSceneBuilder.buildScene(from: room)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                    .frame(height: 320)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                Text("Contents hidden — structural surfaces only (\(room.objects.count) detected object(s) omitted from this view)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let dims = dimensions {
                    dimensionCard(dims)
                } else {
                    Text("Could not compute dimensions — try rescanning with all walls visible.")
                        .foregroundStyle(.red)
                }

                Button {
                    exportUSDZ()
                } label: {
                    Label("Export USDZ Model", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 24)
            }
            .padding(.top)
        }
        .navigationTitle("Scan Results")
    }

    private func dimensionCard(_ dims: ClosetDimensions) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dimensions")
                .font(.headline)
            row("Width", DimensionFormatter.feetInchesFraction(dims.widthInches), raw: dims.widthInches)
            row("Depth", DimensionFormatter.feetInchesFraction(dims.depthInches), raw: dims.depthInches)
            row("Height", DimensionFormatter.feetInchesFraction(dims.heightInches), raw: dims.heightInches)
            Divider()
            HStack {
                Text("Floor area")
                Spacer()
                Text(String(format: "%.2f sq ft", dims.floorAreaSquareFeet))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func row(_ label: String, _ formatted: String, raw: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(formatted)
                .fontWeight(.semibold)
            Text(String(format: "(%.3f\")", raw))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func exportUSDZ() {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ClosetScan.usdz")
        do {
            try room.export(to: path, exportOptions: .parametric)
            print("Exported USDZ to \(path)")
            // Hook up a UIActivityViewController here to share the file if desired.
        } catch {
            print("Export failed: \(error.localizedDescription)")
        }
    }
}
