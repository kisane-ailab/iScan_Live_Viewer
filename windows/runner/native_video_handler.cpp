#include "native_video_handler.h"
#include <windows.h>
#include <turbojpeg.h>
#include <zmq.h>
#include <cstring>
#include <chrono>

// JSON parsing helper (simple implementation for header parsing)
#include <string>
#include <map>

namespace {

// Simple JSON value extractor for our specific header format
std::string ExtractJsonString(const std::string& json, const std::string& key) {
  std::string search = "\"" + key + "\":";
  size_t pos = json.find(search);
  if (pos == std::string::npos) return "";

  pos += search.length();
  while (pos < json.length() && (json[pos] == ' ' || json[pos] == '"')) pos++;

  size_t end = pos;
  while (end < json.length() && json[end] != '"' && json[end] != ',' && json[end] != '}') end++;

  return json.substr(pos, end - pos);
}

double ExtractJsonDouble(const std::string& json, const std::string& key) {
  std::string value = ExtractJsonString(json, key);
  if (value.empty()) return 0.0;
  try {
    return std::stod(value);
  } catch (...) {
    return 0.0;
  }
}

bool ExtractJsonBool(const std::string& json, const std::string& key) {
  std::string value = ExtractJsonString(json, key);
  return value == "true";
}

}  // namespace

NativeVideoHandler::NativeVideoHandler(
    flutter::TextureRegistrar* texture_registrar,
    flutter::BinaryMessenger* messenger)
    : texture_registrar_(texture_registrar) {
  flutter_api_ = std::make_unique<NativeVideoFlutterApi>(messenger);
  OutputDebugStringA("[NativeVideoHandler] Initialized\n");
}

void NativeVideoHandler::SetHwnd(HWND hwnd) {
  hwnd_ = hwnd;
  OutputDebugStringA("[NativeVideoHandler] HWND set\n");
}

void NativeVideoHandler::ProcessFrameCallback(FrameCallbackData* data) {
  if (!data) return;

  FrameInfo info(data->frame_count);
  info.set_cam_idx(data->cam_idx);
  info.set_cam_num(data->cam_num);
  info.set_brightness(data->brightness);
  info.set_motion(data->motion);

  flutter_api_->OnFrameReceived(info, [](){}, [](const FlutterError&){});

  delete data;
}

NativeVideoHandler::~NativeVideoHandler() {
  // Get all stream keys first
  std::vector<int64_t> keys;
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    for (auto& pair : streams_) {
      keys.push_back(pair.first);
    }
  }

  // Clean up all streams (CleanupStream manages its own locking)
  for (int64_t key : keys) {
    CleanupStream(key);
  }

  // Remove all streams
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    streams_.clear();
  }
}

ErrorOr<int64_t> NativeVideoHandler::Initialize(int64_t texture_key) {
  char msg[128];
  sprintf_s(msg, "[NativeVideoHandler] Initialize called for texture_key: %lld\n", texture_key);
  OutputDebugStringA(msg);

  std::lock_guard<std::mutex> lock(streams_mutex_);

  // Check if stream already exists
  if (streams_.find(texture_key) != streams_.end()) {
    return FlutterError("already_initialized", "Stream already initialized for this texture_key");
  }

  // Create new stream
  auto stream = std::make_unique<VideoStream>();
  stream->texture_key = texture_key;

  // Create TurboJPEG decompressor for this stream (thread-safe)
  stream->tj_handle = tjInitDecompress();
  if (!stream->tj_handle) {
    OutputDebugStringA("[NativeVideoHandler] Failed to initialize TurboJPEG for stream\n");
    return FlutterError("tj_error", "Failed to initialize TurboJPEG decompressor");
  }

  // Create pixel buffer texture for this stream
  VideoStream* stream_ptr = stream.get();
  stream->texture = std::make_unique<flutter::TextureVariant>(
    flutter::PixelBufferTexture(
      [stream_ptr](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
        std::lock_guard<std::mutex> lock(stream_ptr->buffer_mutex);
        if (stream_ptr->bgra_buffer.empty() || stream_ptr->frame_width == 0 || stream_ptr->frame_height == 0) {
          return nullptr;
        }

        static thread_local FlutterDesktopPixelBuffer buffer;
        buffer.buffer = stream_ptr->bgra_buffer.data();
        buffer.width = static_cast<size_t>(stream_ptr->frame_width);
        buffer.height = static_cast<size_t>(stream_ptr->frame_height);
        return &buffer;
      }));

  stream->texture_id = texture_registrar_->RegisterTexture(stream->texture.get());

  sprintf_s(msg, "[NativeVideoHandler] Texture registered with ID: %lld for key: %lld\n",
            stream->texture_id, texture_key);
  OutputDebugStringA(msg);

  int64_t texture_id = stream->texture_id;
  current_texture_key_ = texture_key;
  streams_[texture_key] = std::move(stream);

  return texture_id;
}

std::optional<FlutterError> NativeVideoHandler::StartStream(int64_t texture_key, const std::string& zmq_address) {
  char msg[256];
  sprintf_s(msg, "[NativeVideoHandler] StartStream: %s for key: %lld\n",
            zmq_address.c_str(), texture_key);
  OutputDebugStringA(msg);

  std::lock_guard<std::mutex> lock(streams_mutex_);

  auto it = streams_.find(texture_key);
  if (it == streams_.end()) {
    return FlutterError("not_initialized", "Stream not initialized. Call Initialize first.");
  }

  VideoStream* stream = it->second.get();

  if (stream->is_running) {
    return FlutterError("already_running", "Stream is already running");
  }

  // Initialize ZMQ for this stream
  stream->zmq_context = zmq_ctx_new();
  if (!stream->zmq_context) {
    return FlutterError("zmq_error", "Failed to create ZMQ context");
  }

  stream->zmq_socket = zmq_socket(stream->zmq_context, ZMQ_SUB);
  if (!stream->zmq_socket) {
    zmq_ctx_destroy(stream->zmq_context);
    stream->zmq_context = nullptr;
    return FlutterError("zmq_error", "Failed to create ZMQ socket");
  }

  // Set socket options
  int linger = 0;
  zmq_setsockopt(stream->zmq_socket, ZMQ_LINGER, &linger, sizeof(linger));

  int rcvtimeo = 100;  // 100ms receive timeout
  zmq_setsockopt(stream->zmq_socket, ZMQ_RCVTIMEO, &rcvtimeo, sizeof(rcvtimeo));

  // Connect to publisher
  int rc = zmq_connect(stream->zmq_socket, zmq_address.c_str());
  if (rc != 0) {
    zmq_close(stream->zmq_socket);
    zmq_ctx_destroy(stream->zmq_context);
    stream->zmq_socket = nullptr;
    stream->zmq_context = nullptr;
    return FlutterError("zmq_error", "Failed to connect to ZMQ address");
  }

  // Subscribe to all messages
  zmq_setsockopt(stream->zmq_socket, ZMQ_SUBSCRIBE, "", 0);

  // Start receive thread for this stream
  stream->is_running = true;
  stream->receive_thread = std::thread(&NativeVideoHandler::ReceiveLoop, this, texture_key);

  sprintf_s(msg, "[NativeVideoHandler] Stream started successfully for key: %lld\n", texture_key);
  OutputDebugStringA(msg);
  return std::nullopt;
}

void NativeVideoHandler::ReceiveLoop(int64_t texture_key) {
  char msg[128];
  sprintf_s(msg, "[NativeVideoHandler] ReceiveLoop started for key: %lld\n", texture_key);
  OutputDebugStringA(msg);

  VideoStream* stream = nullptr;
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      OutputDebugStringA("[NativeVideoHandler] Stream not found in ReceiveLoop\n");
      return;
    }
    stream = it->second.get();
  }

  std::vector<uint8_t> recv_buffer(2 * 1024 * 1024);  // 2MB buffer

  while (stream->is_running) {
    int size = zmq_recv(stream->zmq_socket, recv_buffer.data(), recv_buffer.size(), 0);

    if (size > 0) {
      // Parse header length (first 4 bytes, little-endian)
      uint32_t header_len;
      memcpy(&header_len, recv_buffer.data(), sizeof(header_len));

      // Validate header length
      if (header_len > 1024 * 1024) {
        // No JSON header, raw JPEG data
        if (DecodeJpeg(stream, recv_buffer.data(), size)) {
          // Notify Flutter
          texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
          ++stream->frame_count;

          // Callback disabled for now - just update frame count
        }
      } else {
        // Parse JSON header
        ParseHeader(stream, recv_buffer.data() + sizeof(header_len), header_len);

        // Decode JPEG data
        const uint8_t* jpeg_data = recv_buffer.data() + sizeof(header_len) + header_len;
        size_t jpeg_size = size - sizeof(header_len) - header_len;

        if (DecodeJpeg(stream, jpeg_data, jpeg_size)) {
          // Notify Flutter that texture is updated
          texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
          ++stream->frame_count;
          // Callback disabled for now
        }
      }
    } else if (size == -1) {
      int err = zmq_errno();
      if (err != EAGAIN) {  // EAGAIN is timeout, which is expected
        char errmsg[128];
        sprintf_s(errmsg, "[NativeVideoHandler] ZMQ recv error: %d for key: %lld\n", err, texture_key);
        OutputDebugStringA(errmsg);
      }
    }
  }

  sprintf_s(msg, "[NativeVideoHandler] ReceiveLoop ended for key: %lld\n", texture_key);
  OutputDebugStringA(msg);
}

void NativeVideoHandler::ParseHeader(VideoStream* stream, const uint8_t* data, uint32_t header_len) {
  std::string json(reinterpret_cast<const char*>(data), header_len);

  // Extract header fields from nested structure: {"header": {...}}
  stream->current_cam_idx = ExtractJsonString(json, "cam_idx");
  stream->current_cam_num = ExtractJsonString(json, "cam_num");
  stream->current_brightness = ExtractJsonDouble(json, "brightness");
  stream->current_motion = ExtractJsonBool(json, "motion");
}

bool NativeVideoHandler::DecodeJpeg(VideoStream* stream, const uint8_t* jpeg_data, size_t jpeg_size) {
  if (!stream->tj_handle || jpeg_size == 0) {
    return false;
  }

  int width, height, subsamp, colorspace;

  // Get JPEG header info
  int rc = tjDecompressHeader3(stream->tj_handle, jpeg_data, static_cast<unsigned long>(jpeg_size),
                                &width, &height, &subsamp, &colorspace);
  if (rc != 0) {
    OutputDebugStringA("[NativeVideoHandler] tjDecompressHeader3 failed\n");
    return false;
  }

  std::lock_guard<std::mutex> lock(stream->buffer_mutex);

  // Resize buffer if needed
  size_t buffer_size = width * height * 4;  // BGRA = 4 bytes per pixel
  if (stream->bgra_buffer.size() != buffer_size) {
    stream->bgra_buffer.resize(buffer_size);
    stream->frame_width = width;
    stream->frame_height = height;

    char msg[128];
    sprintf_s(msg, "[NativeVideoHandler] Frame size: %dx%d for key: %lld\n",
              width, height, stream->texture_key);
    OutputDebugStringA(msg);
  }

  // Decompress JPEG directly to BGRA (SIMD accelerated, ~1-2ms)
  rc = tjDecompress2(
    stream->tj_handle,
    jpeg_data,
    static_cast<unsigned long>(jpeg_size),
    stream->bgra_buffer.data(),
    width,
    width * 4,  // pitch (bytes per row)
    height,
    TJPF_RGBA,  // Output format: RGBA (Flutter Texture expects RGBA)
    TJFLAG_FASTDCT  // Use fast DCT for speed
  );

  if (rc != 0) {
    const char* err = tjGetErrorStr2(stream->tj_handle);
    char msg[256];
    sprintf_s(msg, "[NativeVideoHandler] tjDecompress2 failed: %s\n", err ? err : "unknown");
    OutputDebugStringA(msg);
    return false;
  }

  return true;
}

std::optional<FlutterError> NativeVideoHandler::StopStream(int64_t texture_key) {
  char msg[128];
  sprintf_s(msg, "[NativeVideoHandler] StopStream called for key: %lld\n", texture_key);
  OutputDebugStringA(msg);

  VideoStream* stream = nullptr;
  std::thread thread_to_join;

  {
    std::lock_guard<std::mutex> lock(streams_mutex_);

    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return std::nullopt;  // Already stopped or never started
    }

    stream = it->second.get();
    stream->is_running = false;

    // Move thread out for joining outside the lock
    if (stream->receive_thread.joinable()) {
      thread_to_join = std::move(stream->receive_thread);
    }
  }

  // Join thread outside of lock to avoid deadlock
  if (thread_to_join.joinable()) {
    thread_to_join.join();
  }

  // Cleanup ZMQ resources
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);

    auto it = streams_.find(texture_key);
    if (it != streams_.end()) {
      stream = it->second.get();

      if (stream->zmq_socket) {
        zmq_close(stream->zmq_socket);
        stream->zmq_socket = nullptr;
      }

      if (stream->zmq_context) {
        zmq_ctx_destroy(stream->zmq_context);
        stream->zmq_context = nullptr;
      }
    }
  }

  return std::nullopt;
}

void NativeVideoHandler::CleanupStream(int64_t texture_key) {
  // Note: This function expects streams_mutex_ to NOT be held by caller
  // due to thread join requirements

  VideoStream* stream = nullptr;
  std::thread thread_to_join;

  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return;
    }

    stream = it->second.get();
    stream->is_running = false;

    // Move thread out for joining outside the lock
    if (stream->receive_thread.joinable()) {
      thread_to_join = std::move(stream->receive_thread);
    }
  }

  // Join thread outside of lock to avoid deadlock
  if (thread_to_join.joinable()) {
    thread_to_join.join();
  }

  // Cleanup resources
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return;
    }

    stream = it->second.get();

    // Clean up ZMQ
    if (stream->zmq_socket) {
      zmq_close(stream->zmq_socket);
      stream->zmq_socket = nullptr;
    }

    if (stream->zmq_context) {
      zmq_ctx_destroy(stream->zmq_context);
      stream->zmq_context = nullptr;
    }

    // Unregister texture
    if (stream->texture_id >= 0 && texture_registrar_) {
      texture_registrar_->UnregisterTexture(stream->texture_id);
      stream->texture_id = -1;
    }

    stream->texture.reset();

    // Destroy TurboJPEG handle
    if (stream->tj_handle) {
      tjDestroy(stream->tj_handle);
      stream->tj_handle = nullptr;
    }

    {
      std::lock_guard<std::mutex> buffer_lock(stream->buffer_mutex);
      stream->bgra_buffer.clear();
      stream->frame_width = 0;
      stream->frame_height = 0;
    }
  }
}

ErrorOr<std::optional<FrameInfo>> NativeVideoHandler::GetFrameInfo(int64_t texture_key) {
  std::lock_guard<std::mutex> lock(streams_mutex_);

  auto it = streams_.find(texture_key);
  if (it == streams_.end()) {
    return std::optional<FrameInfo>(std::nullopt);
  }

  VideoStream* stream = it->second.get();

  FrameInfo info(stream->frame_count);
  info.set_cam_idx(stream->current_cam_idx);
  info.set_cam_num(stream->current_cam_num);
  info.set_brightness(stream->current_brightness);
  info.set_motion(stream->current_motion);

  return std::optional<FrameInfo>(info);
}

std::optional<FlutterError> NativeVideoHandler::Dispose(int64_t texture_key) {
  char msg[128];
  sprintf_s(msg, "[NativeVideoHandler] Dispose called for key: %lld\n", texture_key);
  OutputDebugStringA(msg);

  // CleanupStream manages its own locking
  CleanupStream(texture_key);

  // Erase the stream
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it != streams_.end()) {
      streams_.erase(it);
    }
  }

  return std::nullopt;
}
