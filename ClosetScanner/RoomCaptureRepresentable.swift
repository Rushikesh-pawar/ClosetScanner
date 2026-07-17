import SwiftUI
import RoomPlan
import UIKit

/// Wraps Apple's built-in RoomCaptureView (which includes the coaching UI,
/// real-time progress overlay, and "Done" button) so we don't need to build
/// our own scanning UX from scratch.
struct RoomCaptureRepresentable: UIViewRepresentable {
    var onFinish: (CapturedRoom) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.captureSession.delegate = context.coordinator
        view.delegate = context.coordinator
        context.coordinator.captureView = view

        let config = RoomCaptureSession.Configuration()
        view.captureSession.run(configuration: config)

        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No dynamic updates needed; the overlay UI (Cancel/Done buttons)
        // is added once in the Coordinator via makeUIView.
    }

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: Coordinator) {
        uiView.captureSession.stop()
    }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
        let onFinish: (CapturedRoom) -> Void
        let onCancel: () -> Void
        weak var captureView: RoomCaptureView?

        init(onFinish: @escaping (CapturedRoom) -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        // Called when the session stops and RoomPlan wants to know whether
        // to run its post-processing step on the raw capture data.
        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            return error == nil
        }

        // Called once RoomPlan has finished processing into a CapturedRoom.
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            if let error = error {
                print("RoomPlan processing error: \(error.localizedDescription)")
                return
            }
            onFinish(processedResult)
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            if let error = error {
                print("Capture session ended with error: \(error.localizedDescription)")
            }
        }
    }
}
