import SwiftUI
import RoomPlan

struct ScanTabView: View {
    @State private var capturedRoom: CapturedRoom?
    @State private var isScanning = false
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isScanning {
                    RoomCaptureRepresentable(
                        onFinish: { room in
                            self.capturedRoom = room
                            self.isScanning = false
                            self.showResults = true
                        },
                        onCancel: {
                            self.isScanning = false
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "square.dashed.inset.filled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("Closet Scanner")
                            .font(.title.bold())
                        Text("Walk slowly around the closet, keeping all walls, floor, and ceiling in view. Good, even lighting improves accuracy.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            isScanning = true
                        } label: {
                            Label("Start Scan", systemImage: "play.fill")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 32)

                        if !RoomCaptureSession.isSupported {
                            Text("⚠️ This device has no LiDAR scanner. RoomPlan requires an iPhone 12 Pro or later Pro model.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }
            }
            .navigationTitle(isScanning ? "" : "Home")
            .navigationBarHidden(isScanning)
            .navigationDestination(isPresented: $showResults) {
                if let room = capturedRoom {
                    EmptyRoomResultsView(room: room)
                }
            }
        }
    }
}
