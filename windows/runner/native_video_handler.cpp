#include "native_video_handler.h"
#include <windows.h>
#include <winhttp.h>
#include <turbojpeg.h>
#include <zmq.h>
#include <cstring>
#include <chrono>
#include <algorithm>
#include <cctype>

#pragma comment(lib, "winhttp.lib")

// JSON parsing helper (simple implementation for header parsing)
#include <string>
#include <map>

namespace {

// Extract the inner content of a JSON object for a given key
// e.g., for {"header": {"cam_idx": "top_1"}}, ExtractJsonObject(json, "header") returns {"cam_idx": "top_1"}
std::string ExtractJsonObject(const std::string& json, const std::string& key) {
  std::string search = "\"" + key + "\"";
  size_t pos = json.find(search);
  if (pos == std::string::npos) return "";

  // Find the colon after the key
  pos = json.find(':', pos + search.length());
  if (pos == std::string::npos) return "";
  pos++;

  // Skip whitespace
  while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t' || json[pos] == '\n' || json[pos] == '\r')) pos++;

  // Check if it's an object
  if (pos >= json.length() || json[pos] != '{') return "";

  // Find matching closing brace
  size_t start = pos;
  int brace_count = 1;
  pos++;
  while (pos < json.length() && brace_count > 0) {
    if (json[pos] == '{') brace_count++;
    else if (json[pos] == '}') brace_count--;
    pos++;
  }

  return json.substr(start, pos - start);
}

// Simple JSON value extractor for our specific header format
// Handles both quoted strings ("cam_idx": "top_1") and unquoted values ("brightness": 51.7)
std::string ExtractJsonString(const std::string& json, const std::string& key) {
  std::string search = "\"" + key + "\"";
  size_t pos = json.find(search);
  if (pos == std::string::npos) return "";

  // Find the colon after the key
  pos = json.find(':', pos + search.length());
  if (pos == std::string::npos) return "";
  pos++;

  // Skip whitespace
  while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t')) pos++;

  if (pos >= json.length()) return "";

  // Check if value is a quoted string
  if (json[pos] == '"') {
    pos++;  // Skip opening quote
    size_t end = pos;
    while (end < json.length() && json[end] != '"') end++;
    return json.substr(pos, end - pos);
  } else {
    // Unquoted value (number, boolean, null)
    size_t end = pos;
    while (end < json.length() && json[end] != ',' && json[end] != '}' && json[end] != ' ' && json[end] != '\n') end++;
    return json.substr(pos, end - pos);
  }
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

int ExtractJsonInt(const std::string& json, const std::string& key) {
  std::string value = ExtractJsonString(json, key);
  if (value.empty()) return 0;
  try {
    return std::stoi(value);
  } catch (...) {
    return 0;
  }
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
  OutputDebugStringA("[NativeVideoHandler] Destructor called\n");

  // Step 1: Stop all streams first (set is_running = false for all)
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    for (auto& pair : streams_) {
      pair.second->is_running = false;
    }
  }

  // Step 2: Close all ZMQ sockets to unblock receive threads
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    for (auto& pair : streams_) {
      auto& stream = pair.second;
      if (stream->zmq_socket) {
        zmq_close(stream->zmq_socket);
        stream->zmq_socket = nullptr;
      }
    }
  }

  // Step 3: Join all threads (they should exit quickly now)
  std::vector<std::thread> threads_to_join;
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    for (auto& pair : streams_) {
      auto& stream = pair.second;
      if (stream->receive_thread.joinable()) {
        threads_to_join.push_back(std::move(stream->receive_thread));
      }
    }
  }

  for (auto& t : threads_to_join) {
    if (t.joinable()) {
      t.join();
    }
  }

  // Step 4: Clean up remaining resources
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    for (auto& pair : streams_) {
      auto& stream = pair.second;

      if (stream->zmq_context) {
        zmq_ctx_destroy(stream->zmq_context);
        stream->zmq_context = nullptr;
      }

      if (stream->texture_id >= 0 && texture_registrar_) {
        texture_registrar_->UnregisterTexture(stream->texture_id);
        stream->texture_id = -1;
      }

      if (stream->tj_handle) {
        tjDestroy(stream->tj_handle);
        stream->tj_handle = nullptr;
      }
    }
    streams_.clear();
  }

  OutputDebugStringA("[NativeVideoHandler] Destructor completed\n");
}

ErrorOr<int64_t> NativeVideoHandler::Initialize(int64_t texture_key) {
  char msg[128];
  sprintf_s(msg, "[NativeVideoHandler] Initialize called for texture_key: %lld\n", texture_key);
  OutputDebugStringA(msg);

  // If stream already exists, clean it up first (handles rapid reconnection)
  bool needs_cleanup = false;
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    needs_cleanup = (streams_.find(texture_key) != streams_.end());
  }

  if (needs_cleanup) {
    OutputDebugStringA("[NativeVideoHandler] Existing stream found, cleaning up first...\n");
    CleanupStream(texture_key);
    {
      std::lock_guard<std::mutex> lock(streams_mutex_);
      streams_.erase(texture_key);
    }
    OutputDebugStringA("[NativeVideoHandler] Existing stream cleaned up\n");
  }

  std::lock_guard<std::mutex> lock(streams_mutex_);

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

std::optional<FlutterError> NativeVideoHandler::StartStream(int64_t texture_key, const std::string& address) {
  // Trim whitespace
  std::string addr = address;
  size_t start = addr.find_first_not_of(" \t\r\n");
  size_t end = addr.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    addr = addr.substr(start, end - start + 1);
  }

  char msg[256];
  sprintf_s(msg, "[NativeVideoHandler] StartStream: %s for key: %lld\n", addr.c_str(), texture_key);
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

  stream->stream_address = addr;

  // Detect stream type from address
  std::string addr_lower = addr;
  for (auto& c : addr_lower) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));

  if (addr_lower.rfind("http://", 0) == 0 || addr_lower.rfind("https://", 0) == 0) {
    // HTTP MJPEG
    stream->stream_type = StreamType::HTTP_MJPEG;
    OutputDebugStringA("[NativeVideoHandler] Using HTTP MJPEG mode\n");

    if (!StartHttpStream(stream, addr)) {
      return FlutterError("http_error", "Failed to start HTTP stream");
    }
  } else {
    // ZMQ (tcp://)
    stream->stream_type = StreamType::ZMQ;
    OutputDebugStringA("[NativeVideoHandler] Using ZMQ mode\n");

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

    int linger = 0;
    zmq_setsockopt(stream->zmq_socket, ZMQ_LINGER, &linger, sizeof(linger));

    int rcvtimeo = 100;
    zmq_setsockopt(stream->zmq_socket, ZMQ_RCVTIMEO, &rcvtimeo, sizeof(rcvtimeo));

    int rc = zmq_connect(stream->zmq_socket, addr.c_str());
    if (rc != 0) {
      zmq_close(stream->zmq_socket);
      zmq_ctx_destroy(stream->zmq_context);
      stream->zmq_socket = nullptr;
      stream->zmq_context = nullptr;
      return FlutterError("zmq_error", "Failed to connect to ZMQ address");
    }

    zmq_setsockopt(stream->zmq_socket, ZMQ_SUBSCRIBE, "", 0);
  }

  // Start receive thread
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

  if (stream->stream_type == StreamType::HTTP_MJPEG) {
    ReceiveLoopHttp(stream);
  } else {
    ReceiveLoopZmq(stream);
  }

  sprintf_s(msg, "[NativeVideoHandler] ReceiveLoop ended for key: %lld\n", texture_key);
  OutputDebugStringA(msg);
}

void NativeVideoHandler::ReceiveLoopZmq(VideoStream* stream) {
  std::vector<uint8_t> recv_buffer(2 * 1024 * 1024);  // 2MB buffer

  while (stream->is_running && stream->zmq_socket != nullptr) {
    void* socket = stream->zmq_socket;
    if (socket == nullptr) break;

    int size = zmq_recv(socket, recv_buffer.data(), recv_buffer.size(), 0);

    if (size > 0) {
      uint32_t header_len;
      memcpy(&header_len, recv_buffer.data(), sizeof(header_len));

      if (stream->frame_count < 3) {
        char dbg[128];
        sprintf_s(dbg, "[NativeVideoHandler] header_len=%u, msg_size=%d\n", header_len, size);
        OutputDebugStringA(dbg);
      }

      if (header_len > 1024 * 1024) {
        if (stream->is_running && DecodeJpeg(stream, recv_buffer.data(), size)) {
          if (texture_registrar_ && stream->texture_id >= 0) {
            texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
          }
          ++stream->frame_count;
        }
      } else {
        ParseHeader(stream, recv_buffer.data() + sizeof(header_len), header_len);

        const uint8_t* jpeg_data = recv_buffer.data() + sizeof(header_len) + header_len;
        size_t jpeg_size = size - sizeof(header_len) - header_len;

        if (stream->is_running && DecodeJpeg(stream, jpeg_data, jpeg_size)) {
          if (texture_registrar_ && stream->texture_id >= 0) {
            texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
          }
          ++stream->frame_count;
        }
      }
    } else if (size == -1) {
      int err = zmq_errno();
      if (err == ETERM || err == ENOTSOCK) {
        break;
      }
      if (err != EAGAIN) {
        char errmsg[128];
        sprintf_s(errmsg, "[NativeVideoHandler] ZMQ recv error: %d\n", err);
        OutputDebugStringA(errmsg);
      }
    }
  }
}

void NativeVideoHandler::ReceiveLoopHttp(VideoStream* stream) {
  std::vector<uint8_t> buffer(64 * 1024);
  std::vector<uint8_t> accumulator;
  accumulator.reserve(512 * 1024);

  std::string boundary = "frame";  // Default

  while (stream->is_running && stream->http_request) {
    DWORD bytesAvailable = 0;
    if (!WinHttpQueryDataAvailable(stream->http_request, &bytesAvailable)) {
      if (!stream->is_running) break;
      Sleep(10);
      continue;
    }

    if (bytesAvailable == 0) {
      Sleep(1);
      continue;
    }

    DWORD bytesToRead = (std::min)(bytesAvailable, static_cast<DWORD>(buffer.size()));
    DWORD bytesRead = 0;

    if (!WinHttpReadData(stream->http_request, buffer.data(), bytesToRead, &bytesRead)) {
      if (!stream->is_running) break;
      OutputDebugStringA("[NativeVideoHandler] WinHttpReadData failed\n");
      break;
    }

    if (bytesRead == 0) continue;

    accumulator.insert(accumulator.end(), buffer.begin(), buffer.begin() + bytesRead);

    // Parse MJPEG frames
    std::string boundaryMarker = "--" + boundary;
    while (accumulator.size() > 100 && stream->is_running) {
      std::string acc_str(accumulator.begin(), accumulator.end());
      size_t boundary_pos = acc_str.find(boundaryMarker);
      if (boundary_pos == std::string::npos) break;

      size_t headers_start = boundary_pos + boundaryMarker.size();
      size_t headers_end = acc_str.find("\r\n\r\n", headers_start);
      if (headers_end == std::string::npos) break;

      std::string headers = acc_str.substr(headers_start, headers_end - headers_start);

      size_t content_len = 0;
      size_t cl_pos = headers.find("Content-Length:");
      if (cl_pos == std::string::npos) cl_pos = headers.find("content-length:");
      if (cl_pos != std::string::npos) {
        size_t val_start = cl_pos + 15;
        while (val_start < headers.size() && (headers[val_start] == ' ' || headers[val_start] == ':')) val_start++;
        size_t val_end = headers.find_first_of("\r\n", val_start);
        if (val_end != std::string::npos) {
          try { content_len = std::stoul(headers.substr(val_start, val_end - val_start)); } catch (...) {}
        }
      }

      size_t jpeg_offset = headers_end + 4;

      if (content_len == 0) {
        size_t next_boundary = acc_str.find(boundaryMarker, jpeg_offset);
        if (next_boundary != std::string::npos) {
          size_t jpeg_end = next_boundary;
          while (jpeg_end > jpeg_offset && (acc_str[jpeg_end - 1] == '\n' || acc_str[jpeg_end - 1] == '\r')) jpeg_end--;
          content_len = jpeg_end - jpeg_offset;
        } else {
          break;
        }
      }

      if (jpeg_offset + content_len > accumulator.size()) break;

      if (content_len > 0 && stream->is_running) {
        if (DecodeJpeg(stream, &accumulator[jpeg_offset], content_len)) {
          if (texture_registrar_ && stream->texture_id >= 0) {
            texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
          }
          ++stream->frame_count;

          // Set cam_idx from URL
          if (stream->current_cam_idx.empty()) {
            size_t cam_pos = stream->stream_address.find("cam=");
            if (cam_pos != std::string::npos) {
              size_t val_start = cam_pos + 4;
              size_t val_end = stream->stream_address.find_first_of("&# ", val_start);
              if (val_end == std::string::npos) val_end = stream->stream_address.size();
              stream->current_cam_idx = stream->stream_address.substr(val_start, val_end - val_start);
            }
          }
        }
      }

      size_t remove_len = jpeg_offset + content_len;
      while (remove_len < accumulator.size() && (accumulator[remove_len] == '\r' || accumulator[remove_len] == '\n')) remove_len++;
      accumulator.erase(accumulator.begin(), accumulator.begin() + remove_len);
    }

    if (accumulator.size() > 2 * 1024 * 1024) {
      accumulator.clear();
    }
  }
}

void NativeVideoHandler::ParseHeader(VideoStream* stream, const uint8_t* data, uint32_t header_len) {
  // Safety check: skip if no data
  if (data == nullptr || header_len == 0 || header_len > 10000) {
    return;
  }

  try {
    std::string json(reinterpret_cast<const char*>(data), header_len);

    // Debug: print first 200 chars of JSON (first frame only)
    if (stream->frame_count == 0) {
      char debug_msg[512];
      sprintf_s(debug_msg, "[NativeVideoHandler] Raw JSON (len=%u): %.200s\n", header_len, json.c_str());
      OutputDebugStringA(debug_msg);
    }

    // Extract inner "header" object from nested structure: {"header": {...}}
    std::string header_obj = ExtractJsonObject(json, "header");

    // If no "header" wrapper, use the raw json directly (backwards compatibility)
    const std::string& header = header_obj.empty() ? json : header_obj;

    // Extract header fields
    stream->current_cam_idx = ExtractJsonString(header, "cam_idx");
    stream->current_cam_num = ExtractJsonString(header, "cam_num");
    stream->current_brightness = ExtractJsonDouble(header, "brightness");
    stream->current_motion = ExtractJsonBool(header, "motion");

    // Debug: print extracted values (first frame only)
    if (stream->frame_count == 0) {
      char debug_msg[512];
      sprintf_s(debug_msg, "[NativeVideoHandler] Parsed: cam_idx=%.50s, cam_num=%.20s, brightness=%.1f, motion=%d\n",
                stream->current_cam_idx.c_str(), stream->current_cam_num.c_str(),
                stream->current_brightness, stream->current_motion ? 1 : 0);
      OutputDebugStringA(debug_msg);
    }

    // Extract bbox fields from header object
    std::string bbox_obj = ExtractJsonObject(header, "bbox");
    if (!bbox_obj.empty()) {
      stream->current_bbox_x = ExtractJsonInt(bbox_obj, "x");
      stream->current_bbox_y = ExtractJsonInt(bbox_obj, "y");
      stream->current_bbox_w = ExtractJsonInt(bbox_obj, "w");
      stream->current_bbox_h = ExtractJsonInt(bbox_obj, "h");
    } else {
      stream->current_bbox_x = 0;
      stream->current_bbox_y = 0;
      stream->current_bbox_w = 0;
      stream->current_bbox_h = 0;
    }
  } catch (...) {
    // Ignore any parsing errors
    OutputDebugStringA("[NativeVideoHandler] ParseHeader exception\n");
  }
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
  StreamType stream_type = StreamType::ZMQ;

  {
    std::lock_guard<std::mutex> lock(streams_mutex_);

    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return std::nullopt;  // Already stopped or never started
    }

    stream = it->second.get();
    stream->is_running = false;
    stream_type = stream->stream_type;

    // For HTTP: close handles FIRST to unblock WinHttp calls (no timeout)
    // For ZMQ: DON'T close yet - it has 100ms timeout, let thread exit naturally
    if (stream_type == StreamType::HTTP_MJPEG) {
      StopHttpStream(stream);
    }

    // Move thread out for joining outside the lock
    if (stream->receive_thread.joinable()) {
      thread_to_join = std::move(stream->receive_thread);
    }
  }

  // Join thread outside of lock to avoid deadlock
  if (thread_to_join.joinable()) {
    thread_to_join.join();
  }

  // Cleanup remaining resources
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);

    auto it = streams_.find(texture_key);
    if (it != streams_.end()) {
      stream = it->second.get();

      // Cleanup ZMQ (now safe - thread has exited)
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
  StreamType stream_type = StreamType::ZMQ;

  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return;
    }

    stream = it->second.get();
    stream->is_running = false;
    stream_type = stream->stream_type;

    // For HTTP: close handles FIRST to unblock WinHttp calls (no timeout)
    // For ZMQ: DON'T close yet - it has 100ms timeout, let thread exit naturally
    if (stream_type == StreamType::HTTP_MJPEG) {
      StopHttpStream(stream);
    }

    // Move thread out for joining outside the lock
    if (stream->receive_thread.joinable()) {
      thread_to_join = std::move(stream->receive_thread);
    }
  }

  // Join thread outside of lock to avoid deadlock
  if (thread_to_join.joinable()) {
    thread_to_join.join();
  }

  // Cleanup remaining resources
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    auto it = streams_.find(texture_key);
    if (it == streams_.end()) {
      return;
    }

    stream = it->second.get();

    // Clean up ZMQ (now safe - thread has exited)
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

  // Set resolution
  if (stream->frame_width > 0 && stream->frame_height > 0) {
    info.set_width(stream->frame_width);
    info.set_height(stream->frame_height);
  }

  // Set bbox if available
  if (stream->current_bbox_w > 0 && stream->current_bbox_h > 0) {
    info.set_bbox_x(stream->current_bbox_x);
    info.set_bbox_y(stream->current_bbox_y);
    info.set_bbox_w(stream->current_bbox_w);
    info.set_bbox_h(stream->current_bbox_h);
  }

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

bool NativeVideoHandler::StartHttpStream(VideoStream* stream, const std::string& url) {
  OutputDebugStringA("[NativeVideoHandler] StartHttpStream\n");

  // Parse URL (http://host:port/path)
  std::string host;
  std::string path = "/";
  int port = 80;
  bool is_https = false;

  std::string work_url = url;
  if (work_url.rfind("https://", 0) == 0) {
    is_https = true;
    port = 443;
    work_url = work_url.substr(8);
  } else if (work_url.rfind("http://", 0) == 0) {
    work_url = work_url.substr(7);
  }

  // Find path
  size_t path_pos = work_url.find('/');
  if (path_pos != std::string::npos) {
    path = work_url.substr(path_pos);
    work_url = work_url.substr(0, path_pos);
  }

  // Find port
  size_t port_pos = work_url.find(':');
  if (port_pos != std::string::npos) {
    host = work_url.substr(0, port_pos);
    try { port = std::stoi(work_url.substr(port_pos + 1)); } catch (...) {}
  } else {
    host = work_url;
  }

  char dbg[512];
  sprintf_s(dbg, "[NativeVideoHandler] HTTP: host=%s, port=%d, path=%s\n", host.c_str(), port, path.c_str());
  OutputDebugStringA(dbg);

  // Convert host to wide string
  std::wstring whost;
  whost.reserve(host.size());
  for (char c : host) {
    whost.push_back(static_cast<wchar_t>(static_cast<unsigned char>(c)));
  }

  // Convert path to wide string
  std::wstring wpath;
  wpath.reserve(path.size());
  for (char c : path) {
    wpath.push_back(static_cast<wchar_t>(static_cast<unsigned char>(c)));
  }

  // Create session
  stream->http_session = WinHttpOpen(
    L"iScan_Live_Viewer/1.0",
    WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
    WINHTTP_NO_PROXY_NAME,
    WINHTTP_NO_PROXY_BYPASS,
    0
  );

  if (!stream->http_session) {
    OutputDebugStringA("[NativeVideoHandler] WinHttpOpen failed\n");
    return false;
  }

  // Set timeouts: resolve=5s, connect=5s, send=5s, receive=30s (streaming)
  WinHttpSetTimeouts(stream->http_session, 5000, 5000, 5000, 30000);

  // Connect
  stream->http_connection = WinHttpConnect(
    stream->http_session,
    whost.c_str(),
    static_cast<INTERNET_PORT>(port),
    0
  );

  if (!stream->http_connection) {
    DWORD err = GetLastError();
    sprintf_s(dbg, "[NativeVideoHandler] WinHttpConnect failed: %lu\n", err);
    OutputDebugStringA(dbg);
    WinHttpCloseHandle(stream->http_session);
    stream->http_session = nullptr;
    return false;
  }

  // Open request
  DWORD flags = is_https ? WINHTTP_FLAG_SECURE : 0;
  stream->http_request = WinHttpOpenRequest(
    stream->http_connection,
    L"GET",
    wpath.c_str(),
    NULL,
    WINHTTP_NO_REFERER,
    WINHTTP_DEFAULT_ACCEPT_TYPES,
    flags
  );

  if (!stream->http_request) {
    DWORD err = GetLastError();
    sprintf_s(dbg, "[NativeVideoHandler] WinHttpOpenRequest failed: %lu\n", err);
    OutputDebugStringA(dbg);
    WinHttpCloseHandle(stream->http_connection);
    WinHttpCloseHandle(stream->http_session);
    stream->http_connection = nullptr;
    stream->http_session = nullptr;
    return false;
  }

  // Send request
  if (!WinHttpSendRequest(stream->http_request, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
    DWORD err = GetLastError();
    sprintf_s(dbg, "[NativeVideoHandler] WinHttpSendRequest failed: %lu\n", err);
    OutputDebugStringA(dbg);
    WinHttpCloseHandle(stream->http_request);
    WinHttpCloseHandle(stream->http_connection);
    WinHttpCloseHandle(stream->http_session);
    stream->http_request = nullptr;
    stream->http_connection = nullptr;
    stream->http_session = nullptr;
    return false;
  }

  // Receive response
  if (!WinHttpReceiveResponse(stream->http_request, NULL)) {
    DWORD err = GetLastError();
    sprintf_s(dbg, "[NativeVideoHandler] WinHttpReceiveResponse failed: %lu\n", err);
    OutputDebugStringA(dbg);
    WinHttpCloseHandle(stream->http_request);
    WinHttpCloseHandle(stream->http_connection);
    WinHttpCloseHandle(stream->http_session);
    stream->http_request = nullptr;
    stream->http_connection = nullptr;
    stream->http_session = nullptr;
    return false;
  }

  // Check status code
  DWORD statusCode = 0;
  DWORD statusCodeSize = sizeof(statusCode);
  WinHttpQueryHeaders(stream->http_request, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                      WINHTTP_HEADER_NAME_BY_INDEX, &statusCode, &statusCodeSize, WINHTTP_NO_HEADER_INDEX);

  sprintf_s(dbg, "[NativeVideoHandler] HTTP status: %lu\n", statusCode);
  OutputDebugStringA(dbg);

  if (statusCode != 200) {
    WinHttpCloseHandle(stream->http_request);
    WinHttpCloseHandle(stream->http_connection);
    WinHttpCloseHandle(stream->http_session);
    stream->http_request = nullptr;
    stream->http_connection = nullptr;
    stream->http_session = nullptr;
    return false;
  }

  OutputDebugStringA("[NativeVideoHandler] HTTP stream started successfully\n");
  return true;
}

void NativeVideoHandler::StopHttpStream(VideoStream* stream) {
  if (stream->http_request) {
    WinHttpCloseHandle(stream->http_request);
    stream->http_request = nullptr;
  }
  if (stream->http_connection) {
    WinHttpCloseHandle(stream->http_connection);
    stream->http_connection = nullptr;
  }
  if (stream->http_session) {
    WinHttpCloseHandle(stream->http_session);
    stream->http_session = nullptr;
  }
}
