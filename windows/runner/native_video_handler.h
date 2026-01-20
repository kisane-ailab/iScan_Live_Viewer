#pragma once

#include "native_video_api.g.h"
#include <flutter/texture_registrar.h>
#include <windows.h>
#include <thread>
#include <atomic>
#include <mutex>
#include <vector>
#include <map>
#include <queue>
#include <functional>

// Custom Windows message for frame callbacks
#define WM_NATIVE_VIDEO_FRAME (WM_USER + 100)

// Frame callback data (passed via PostMessage)
struct FrameCallbackData {
  int64_t texture_key;
  int64_t frame_count;
  std::string cam_idx;
  std::string cam_num;
  double brightness;
  bool motion;
};

// Forward declarations for external libraries
typedef void* tjhandle;

// Per-stream data structure
struct VideoStream {
  int64_t texture_key = -1;
  int64_t texture_id = -1;
  std::unique_ptr<flutter::TextureVariant> texture;
  std::vector<uint8_t> bgra_buffer;
  int frame_width = 0;
  int frame_height = 0;

  // ZMQ handles (per stream)
  void* zmq_context = nullptr;
  void* zmq_socket = nullptr;

  // TurboJPEG handle (per stream for thread safety)
  tjhandle tj_handle = nullptr;

  // Threading
  std::thread receive_thread;
  std::atomic<bool> is_running{false};
  std::mutex buffer_mutex;

  // Stats
  int64_t frame_count = 0;
  std::chrono::steady_clock::time_point last_callback_time;

  // Current frame info
  std::string current_cam_idx;
  std::string current_cam_num;
  double current_brightness = 0.0;
  bool current_motion = false;
  int current_bbox_x = 0;
  int current_bbox_y = 0;
  int current_bbox_w = 0;
  int current_bbox_h = 0;
};

class NativeVideoHandler : public NativeVideoHostApi {
 public:
  NativeVideoHandler(
    flutter::TextureRegistrar* texture_registrar,
    flutter::BinaryMessenger* messenger);
  ~NativeVideoHandler();

  // Set window handle for message posting (call from main thread)
  void SetHwnd(HWND hwnd);

  // Process frame callback (call from main thread message handler)
  void ProcessFrameCallback(FrameCallbackData* data);

  // NativeVideoHostApi implementation
  ErrorOr<int64_t> Initialize(int64_t texture_key) override;
  std::optional<FlutterError> StartStream(int64_t texture_key, const std::string& zmq_address) override;
  std::optional<FlutterError> StopStream(int64_t texture_key) override;
  ErrorOr<std::optional<FrameInfo>> GetFrameInfo(int64_t texture_key) override;
  std::optional<FlutterError> Dispose(int64_t texture_key) override;

 private:
  void ReceiveLoop(int64_t texture_key);
  bool DecodeJpeg(VideoStream* stream, const uint8_t* jpeg_data, size_t jpeg_size);
  void ParseHeader(VideoStream* stream, const uint8_t* data, uint32_t header_len);
  void CleanupStream(int64_t texture_key);

  flutter::TextureRegistrar* texture_registrar_;
  std::unique_ptr<NativeVideoFlutterApi> flutter_api_;

  // Window handle for PostMessage (set from main thread)
  HWND hwnd_ = nullptr;

  // Multiple streams indexed by texture_key
  std::map<int64_t, std::unique_ptr<VideoStream>> streams_;
  std::mutex streams_mutex_;

  // Current active stream key (for StartStream/StopStream)
  int64_t current_texture_key_ = -1;
};
