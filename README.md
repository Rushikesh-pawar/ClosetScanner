# ClosetScanner

A native iOS application that uses Apple's **RoomPlan**, **ARKit**, and the iPhone's **LiDAR** sensor to scan a closet, reconstruct its structural geometry, estimate its dimensions, and display a clean visualization of the space with detected contents excluded.

This project was built as a rapid prototype to demonstrate room scanning, structural reconstruction, and measurement validation using Apple's spatial computing frameworks.

---

# Features

- Scan closets using Apple's RoomPlan framework
- Uses LiDAR and RGB camera for room reconstruction
- Reconstructs only structural elements (walls, floor, ceiling, doors, openings)
- Excludes detected furniture and stored objects from the rendered model
- Estimates closet width, depth, and height
- Interactive SceneKit visualization
- Built-in measurement validation tool
- Native SwiftUI application

---

# Requirements

- macOS with **Xcode 15+**
- iPhone with LiDAR
  - iPhone 12 Pro / Pro Max
  - iPhone 13 Pro / Pro Max
  - iPhone 14 Pro / Pro Max
  - iPhone 15 Pro / Pro Max
  - iPhone 16 Pro / Pro Max
  - iPhone 17 Pro / Pro Max
- iOS 16+
- Apple Developer Account (Free account is sufficient)

> **Note:** RoomPlan does **not** run inside the iOS Simulator.

---

# Setup

1. Clone the repository

```bash
git clone https://github.com/Rushikesh-pawar/ClosetScanner.git
```

2. Open

```
ClosetScanner.xcodeproj
```

3. Under **Signing & Capabilities**

Select your Apple ID Team.

4. Add the following permission inside **Info.plist**

```
Privacy - Camera Usage Description

"This app uses the camera and LiDAR sensor to scan closets."
```

5. Build and run on a physical LiDAR-enabled iPhone.

---

# Technical Stack

- Swift
- SwiftUI
- RoomPlan
- ARKit
- SceneKit
- LiDAR
- CapturedRoom API

---

# System Architecture

```
              LiDAR + RGB Camera
                      │
                      ▼
                   ARKit
                      │
                      ▼
                Apple RoomPlan
                      │
                      ▼
                 CapturedRoom
                      │
      ┌───────────────┴───────────────┐
      │                               │
Detected Objects              Structural Elements
Ignored                  Walls • Floor • Ceiling
                                     │
                                     ▼
                      StructuralSceneBuilder
                                     │
                                     ▼
                               SceneKit View
                                     │
                                     ▼
                         Dimension Estimation
                                     │
                                     ▼
                         Accuracy Validation
```

---

# Project Structure

### RoomCaptureRepresentable.swift

Wraps Apple's built-in `RoomCaptureView`.

Responsibilities:

- Launches RoomPlan scanning
- Displays Apple's coaching interface
- Receives the final `CapturedRoom`
- Passes scan results into the application

---

### StructuralSceneBuilder.swift

Generates the 3D SceneKit visualization.

Instead of rendering every object detected by RoomPlan, the application reconstructs **only the structural geometry**:

- Walls
- Floor
- Ceiling
- Doors
- Windows
- Openings

**Important**

Objects are **not removed using generative AI or image inpainting**.

RoomPlan already classifies structural surfaces separately from detected objects. This application simply reconstructs the structural geometry while intentionally excluding detected objects from the rendered SceneKit scene.

---

### ClosetDimensions.swift

Estimates closet dimensions from the structural wall geometry contained inside `CapturedRoom`.

Outputs

- Width
- Depth
- Height

Measurements are displayed rounded to the nearest **1/16 inch**.

---

### AccuracyTestView.swift

Validation utility for comparing:

- Manual tape measurements
- RoomPlan measurements

Computes:

- Absolute Error
- Percentage Error
- Mean Absolute Error (MAE)
- Maximum Error

---

# Accuracy Validation

The prototype was validated by comparing the application's measured dimensions against manual tape measurements of a residential closet.

| Dimension | App (in) | Tape (in) | Absolute Error |
|-----------|----------:|----------:|---------------:|
| Width | 59.107 | 60.000 | 0.893 in |
| Depth | 27.496 | 27.000 | 0.496 in |
| Height | 101.606 | 101.200 | 0.406 in |

## Results

**Mean Absolute Error (MAE):**

```
0.60 inches
```

**Maximum Absolute Error**

```
0.89 inches
```

### Percentage Error

| Dimension | Error |
|-----------|-------:|
| Width | 1.49% |
| Depth | 1.84% |
| Height | 0.40% |

The prototype demonstrates reliable structural reconstruction and dimension estimation using Apple's RoomPlan framework.

The observed measurement error is primarily influenced by:

- LiDAR sensor resolution
- Scan trajectory
- Wall and corner reconstruction
- RoomPlan's geometric simplification of captured spaces

---

# Current Limitations

- Measurement accuracy depends on LiDAR sensor resolution and scan quality.
- RoomPlan simplifies wall geometry during reconstruction.
- Width and depth estimation currently assumes a rectangular closet layout.
- Irregular or complex room geometries would require per-wall measurements instead of a single width × depth estimate.

---

# Future Improvements

Potential future enhancements include:

- Multi-scan averaging for increased measurement consistency
- Raw ARKit SceneDepth fusion
- Custom plane fitting for improved wall estimation
- Confidence scoring for measurements
- Reference-object based calibration
- Manual corner adjustment
- Validation across multiple room geometries and lighting conditions

---

# Live Demo Flow

1. Launch the application.
2. Tap **Start Scan**.
3. Slowly walk around the closet while RoomPlan captures the environment.
4. Complete the scan.
5. Display the reconstructed structural model.
6. Rotate and inspect the 3D visualization.
7. Show calculated width, depth, and height.
8. Open the Accuracy Validation screen.
9. Compare measured values against manual tape measurements.

---

# Engineering Decisions

Instead of attempting to remove objects using generative AI, the application focuses on accurate geometric reconstruction.

RoomPlan already separates structural elements from detected objects, allowing the application to reconstruct an "empty" closet by rendering only the structural geometry. This deterministic approach is significantly more reliable for dimension estimation than attempting to hallucinate hidden wall surfaces.

---

# Repository

GitHub

https://github.com/Rushikesh-pawar/ClosetScanner

---

# Author

**Rushikesh Pawar**

Master of Science in Computer Science

Northeastern University

Boston, Massachusetts
