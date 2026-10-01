# Flickit — Technical Interview & Architectural Notes

This document provides clear, concise, and technically grounded explanations for the key design and engineering decisions in **Flickit**. Use these notes to explain the system during an interview.

---

### 1. Why Flutter?
* **High Performance**: Flutter compiles directly to native ARM64 machine code via Skia / Impeller, maintaining 60–120 FPS UI rendering even while running concurrent vision algorithms.
* **Unified Cross-Platform Engine**: A single codebase runs on Android and iOS while accessing platform-specific camera sensors and neural processing hardware.
* **Declarative Reactivity**: Combining Flutter with Riverpod provides predictable, unidirectional data flow where camera status, vision metrics, and tap states update reactively without unnecessary widget rebuilds.

---

### 2. How Camera Frames Are Captured
* The app uses Flutter's official `camera` plugin with the Android `Camera2` API backend.
* It initializes with `ResolutionPreset.medium` (~720x480 or 1280x720) in `ImageFormatGroup.yuv420`.
* Rather than capturing static snapshots, it registers an image stream listener (`startImageStream`). This yields streaming byte planes directly from camera memory without expensive JPEG encoding.

---

### 3. How YOLO Pose Is Used
* Ultralytics YOLO Pose (YOLOv8-pose or YOLO11-pose) performs **joint object detection and keypoint estimation** in a single neural network forward pass.
* The model takes a normalized input tensor (e.g., $1 \times 3 \times 640 \times 640$).
* The output is a multi-head prediction grid (8400 candidate anchor boxes) containing:
  1. Person bounding box coordinates $[cx, cy, w, h]$
  2. Person box confidence score
  3. 17 COCO pose keypoints, each having $(x, y, \text{confidence})$
  4. Class scores for sports ball / football.

---

### 4. What a Pose Keypoint Is
* A **pose keypoint** is a predicted $(x, y)$ coordinate representing an anatomical joint in pixel or normalized space, accompanied by a detection confidence score between $0.0$ and $1.0$.
* For football toe taps, the most critical keypoints are:
  - `left_ankle` (COCO index 15)
  - `right_ankle` (COCO index 16)
  - `left_knee` / `right_knee` (indices 13 & 14, used to compute leg direction vectors).
* When a model supports extended foot keypoints (such as big toe or foot index), our `PoseKeypoints` domain model seamlessly prioritizes the toe coordinates over the ankle.

---

### 5. How the Football Is Detected
* The football is detected either through:
  - A multi-class YOLO model that detects both `person` (class 0) and `sports ball` (COCO class 32).
  - A dedicated object detection head running alongside the pose model.
* The detector extracts the football bounding box, computes its geometric center $(cx, cy)$, and calculates an effective radius:
  $$r = \frac{\text{width} + \text{height}}{4}$$
* All coordinates are normalized to $[0.0, 1.0]$ relative to image dimensions so distance calculations remain resolution-independent.

---

### 6. How Foot-to-Ball Distance Is Calculated
* Given the football center $C_{\text{ball}} = (x_b, y_b)$ and foot point $P_{\text{foot}} = (x_f, y_f)$, we compute Euclidean distance:
  $$d = \sqrt{(x_f - x_b)^2 + (y_f - y_b)^2}$$
* We then **normalize** this distance by the ball's radius:
  $$\text{NormalizedDistance} = \frac{d}{r_{\text{ball}}}$$
* **Why normalize?** If the player is standing further away from the camera, both the ball and foot appear smaller on screen. Dividing by ball radius makes the contact threshold invariant to camera distance.

---

### 7. How Contact Is Detected
* Contact is not just a distance check; it requires:
  1. $\text{Keypoint Confidence} \ge \text{minimum threshold}$ (e.g., $0.40$).
  2. $\text{Ball Confidence} \ge \text{minimum threshold}$ (e.g., $0.40$).
  3. $\text{NormalizedDistance} \le \text{contactDistanceRatio}$ (e.g., $1.30$).
  4. Foot trajectory showing positive approach velocity toward the ball.

---

### 8. Why a State Machine Is Required
* A naive distance check ($d < \text{threshold}$) fails catastrophically because a foot touching a ball remains in the contact zone for 5 to 15 consecutive camera frames.
* The state machine enforces sequential phases:
  $$\text{AWAY} \longrightarrow \text{APPROACHING} \longrightarrow \text{CONTACT} \longrightarrow \text{RELEASE} \longrightarrow \text{AWAY}$$
* The counter **only increments when transitioning into CONTACT**.
* Even if the foot rests on the ball for 3 seconds across 90 frames, the state stays in `CONTACT`, preventing false duplicate counts.

---

### 9. How Duplicate Taps Are Prevented
Flickit uses a **dual-layer debouncing strategy**:
1. **Hysteresis**:
   - Contact threshold: $1.30 \times r$
   - Release threshold: $1.70 \times r$
   - Because $1.30 < 1.70$, minor foot vibrations or detection jitter around the boundary line cannot trigger spurious tap events. The foot must clearly move away before another tap is possible.
2. **Temporal Cooldown**:
   - A minimum time interval (e.g., $320\text{ ms}$) must elapse between consecutive valid taps, rejecting physical bounce noise.

---

### 10. How Frame Skipping Improves Performance
* Running deep learning inference synchronously on every camera frame at 30–60 FPS would overwhelm mobile GPUs and cause UI frame drops.
* Flickit implements **Controlled Asynchronous Frame Skipping**:
  ```dart
  if (_isProcessingFrame) return; // Drop frame if previous inference is still executing
  if (timeSinceLastFrame < minFrameInterval) return; // Throttle to ~12 FPS
  ```
* The camera preview continues rendering at a fluid 60 FPS while the vision model runs at a stable, thermally efficient 10–12 FPS on the latest frame. No stale frames are queued.

---

### 11. How Lifecycle Handling Works
* Registered with Flutter's `WidgetsBindingObserver`:
  - **`paused` / `inactive`**: The user opened another app or locked the screen. Flickit immediately stops camera streaming and suspends inference to conserve battery and avoid OS resource revocation.
  - **`resumed`**: Cleanly reinitializes camera controller and resets detector tracking histories.
  - **`detached`**: Safely releases native camera memory buffers and neural runtime delegates.

---

### 12. Why the ML Code Is Separated from Business Logic
* The `PoseDetector` abstract interface decouples machine learning inference from the `ToeTapDetector` state machine.
* **Benefits**:
  - The core toe-tap algorithm is 100% pure Dart, enabling fast unit testing without native camera or GPU dependencies.
  - We can swap the model (e.g., from YOLOv8 to YOLO11, or TFLite to ONNX Runtime) by writing a new adapter without touching any UI or counting logic.
  - Allows `MockPoseDetector` for instant simulator testing during local development.

---

### 13. How the App Handles Missing Detections
* In physical sports, limbs and balls can be occluded momentarily (e.g., by the player's other leg or motion blur).
* Rather than crashing or resetting immediately, Flickit maintains an **occlusion tolerance buffer** (`maxMissingFramesBeforeReset = 6`).
* If detection drops for 1–2 frames, the foot tracker holds its state. If occlusion persists beyond the tolerance threshold, the state machine resets cleanly to `AWAY`.

---

### 14. How the Algorithm Could Be Improved in the Future
1. **Kalman Filtering / EMA Smoothing**: Applying a constant-velocity Kalman filter to keypoints would reduce sensor jitter and improve velocity calculations under high motion.
2. **Audio Verification**: Integrating microphone input to detect the acoustic "thud" of shoe-to-ball contact as a secondary multi-modal confirmation signal.
3. **Toe-Tip Extrapolation**: Extending ankle keypoints along the tibia vector toward the ground to approximate the physical shoe toe when the model only predicts ankles.
4. **Accelerometer Sensor Fusion**: Cross-referencing device stability via phone IMU to compensate for handheld camera vibrations.
