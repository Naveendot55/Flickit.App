# Model Assets Directory

Place your exported Ultralytics YOLO Pose model here:

- Filename: `yolov8n_pose.tflite` (or `yolo11n_pose.tflite`)
- Format: FlatBuffers Float32 / Float16 TFLite model or ONNX
- Input Tensor: `[1, 3, 640, 640]` normalized RGB
- Output Tensor: `[1, 56, 8400]` (Bounding Box `[cx, cy, w, h]`, person confidence, and 17 COCO pose keypoints `[x, y, conf]`, plus football class confidence)

### Exporting from Ultralytics:
```bash
pip install ultralytics
yolo export model=yolov8n-pose.pt format=tflite imgsz=640
```
Then copy the generated `.tflite` file into this directory (`assets/models/yolov8n_pose.tflite`).
