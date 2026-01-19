# 멀티 스트림 구현 이슈 보고서

## 개요

Native C++ 비디오 렌더러에서 다중 카메라 스트림을 지원하도록 구현하는 과정에서 발생한 문제들과 해결 방안을 정리한 문서입니다.

---

## 1. 싱글톤 상태 문제 (핵심 원인)

### 문제 상황
```cpp
// 기존 코드 - 단일 스트림만 고려
class NativeVideoHandler {
  int64_t current_texture_key_ = -1;  // 마지막 Initialize의 키만 저장

  ErrorOr<int64_t> Initialize(int64_t texture_key) {
    current_texture_key_ = texture_key;  // 덮어씀
    // ...
  }

  std::optional<FlutterError> StartStream(const std::string& zmq_address) {
    auto it = streams_.find(current_texture_key_);  // 항상 마지막 키 사용
    // ...
  }
};
```

### 증상
- 카메라 개별 연결: 정상 작동
- 카메라 전체 연결: 마지막 카메라만 작동 (또는 빠른 카메라만 작동)

### 원인 분석
1. Camera 0: `Initialize(0)` → `current_texture_key_ = 0`
2. Camera 1: `Initialize(1)` → `current_texture_key_ = 1` (덮어씀)
3. Camera 0: `StartStream()` → `current_texture_key_`가 1이므로 **Camera 1의 스트림이 시작됨**

### 해결책
모든 API 메소드에 `texture_key` 파라미터 추가:

```cpp
// 수정 후
std::optional<FlutterError> StartStream(int64_t texture_key, const std::string& zmq_address);
std::optional<FlutterError> StopStream(int64_t texture_key);
std::optional<FlutterError> Dispose(int64_t texture_key);
ErrorOr<std::optional<FrameInfo>> GetFrameInfo(int64_t texture_key);
```

---

## 2. 스레드 안전성 문제 (콜백)

### 문제 상황
```cpp
// 워커 스레드에서 실행
void NativeVideoHandler::ReceiveLoop(int64_t texture_key) {
  while (stream->is_running) {
    // JPEG 디코딩...

    // 플랫폼 스레드가 아닌 워커 스레드에서 호출 - 크래시!
    flutter_api_->OnFrameReceived(info, [](){}, [](const FlutterError&){});
  }
}
```

### 증상
```
[ERROR:flutter/shell/common/shell.cc(1178)] The 'dev.flutter.pigeon...onFrameReceived'
channel sent a message from native to Flutter on a non-platform thread.
```

### 원인 분석
- Flutter Pigeon API는 **플랫폼 스레드(UI 스레드)** 에서만 호출 가능
- ZMQ 수신 루프는 **별도 워커 스레드**에서 실행
- 스레드 간 직접 콜백 호출 시 크래시 발생

### 시도한 해결책들

#### 방법 1: PostMessage (실패)
```cpp
// Windows 메시지 큐를 통한 스레드 간 통신 시도
PostMessage(hwnd_, WM_NATIVE_VIDEO_FRAME, 0, reinterpret_cast<LPARAM>(data));
```
- 결과: 메시지 폭주로 인한 불안정

#### 방법 2: 폴링 방식 (성공)
```dart
// Dart에서 100ms마다 프레임 정보 조회
Timer.periodic(Duration(milliseconds: 100), (_) async {
  final info = await _renderer!.getFrameInfo();
  // 상태 업데이트
});
```

```cpp
// C++에서 동기 API로 프레임 정보 제공
ErrorOr<std::optional<FrameInfo>> GetFrameInfo(int64_t texture_key) {
  std::lock_guard<std::mutex> lock(streams_mutex_);
  auto it = streams_.find(texture_key);
  if (it == streams_.end()) return std::nullopt;

  VideoStream* stream = it->second.get();
  FrameInfo info(stream->frame_count);
  // ...
  return info;
}
```

---

## 3. 리소스 공유 문제 (TurboJPEG)

### 문제 상황
```cpp
// 기존 - 모든 스트림이 하나의 디코더 공유
class NativeVideoHandler {
  tjhandle tj_handle_;  // 공유 핸들

  bool DecodeJpeg(...) {
    tjDecompress2(tj_handle_, ...);  // 동시 호출 시 충돌!
  }
};
```

### 원인 분석
- `tjDecompress2`는 **스레드 안전하지 않음**
- 여러 스트림이 동시에 디코딩 시 데이터 손상 또는 크래시

### 해결책
각 스트림에 개별 TurboJPEG 핸들 할당:

```cpp
struct VideoStream {
  tjhandle tj_handle = nullptr;  // 스트림별 핸들
  // ...
};

ErrorOr<int64_t> Initialize(int64_t texture_key) {
  auto stream = std::make_unique<VideoStream>();
  stream->tj_handle = tjInitDecompress();  // 개별 생성
  // ...
}

void CleanupStream(int64_t texture_key) {
  if (stream->tj_handle) {
    tjDestroy(stream->tj_handle);  // 개별 해제
  }
}
```

---

## 4. 뮤텍스 교착 상태 문제

### 문제 상황
```cpp
// 기존 코드 - 교착 가능
std::optional<FlutterError> StopStream() {
  std::lock_guard<std::mutex> lock(streams_mutex_);  // 뮤텍스 잠금

  stream->is_running = false;
  stream->receive_thread.join();  // 스레드가 뮤텍스 필요하면 교착!
  // ...
}
```

### 원인 분석
1. `StopStream`이 `streams_mutex_` 잠금
2. `receive_thread.join()` 호출하여 스레드 종료 대기
3. 워커 스레드가 종료 전 `streams_mutex_` 접근 시도
4. **교착 상태 (Deadlock)**

### 해결책
뮤텍스 외부에서 스레드 join:

```cpp
std::optional<FlutterError> StopStream(int64_t texture_key) {
  std::thread thread_to_join;

  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    stream->is_running = false;

    // 스레드를 밖으로 이동
    if (stream->receive_thread.joinable()) {
      thread_to_join = std::move(stream->receive_thread);
    }
  }  // 뮤텍스 해제

  // 뮤텍스 없이 join
  if (thread_to_join.joinable()) {
    thread_to_join.join();
  }

  // ZMQ 정리는 별도 뮤텍스 블록에서
  {
    std::lock_guard<std::mutex> lock(streams_mutex_);
    // cleanup...
  }
}
```

---

## 5. 최종 아키텍처

### 멀티 스트림 데이터 구조
```cpp
struct VideoStream {
  int64_t texture_key = -1;
  int64_t texture_id = -1;
  std::unique_ptr<flutter::TextureVariant> texture;
  std::vector<uint8_t> bgra_buffer;
  int frame_width = 0;
  int frame_height = 0;

  // 스트림별 ZMQ
  void* zmq_context = nullptr;
  void* zmq_socket = nullptr;

  // 스트림별 TurboJPEG
  tjhandle tj_handle = nullptr;

  // 스레딩
  std::thread receive_thread;
  std::atomic<bool> is_running{false};
  std::mutex buffer_mutex;

  // 프레임 정보
  int64_t frame_count = 0;
  std::string current_cam_idx;
  std::string current_cam_num;
  double current_brightness = 0.0;
  bool current_motion = false;
};

class NativeVideoHandler {
  std::map<int64_t, std::unique_ptr<VideoStream>> streams_;
  std::mutex streams_mutex_;
};
```

### 데이터 흐름
```
[ZMQ Publisher]
      │
      ▼ (TCP)
[C++ ReceiveLoop] ─── 워커 스레드 (스트림별)
      │
      ▼ (TurboJPEG SIMD 디코딩)
[BGRA Buffer] ─── 스트림별 버퍼
      │
      ▼ (MarkTextureFrameAvailable)
[Flutter Texture] ─── GPU 텍스처
      │
      ▼
[UI 렌더링]

[Dart Timer] ──────────────────────▶ [GetFrameInfo API] ──▶ [UI 상태 업데이트]
            (100ms 폴링)                 (동기 호출)
```

---

## 요약

| 문제 유형 | 원인 | 해결책 |
|----------|------|--------|
| 싱글톤 상태 | `current_texture_key_` 공유 | API에 `texture_key` 파라미터 추가 |
| 스레드 콜백 | 워커→UI 스레드 직접 콜백 | 폴링 방식으로 변경 |
| 리소스 공유 | TurboJPEG 핸들 공유 | 스트림별 핸들 할당 |
| 뮤텍스 교착 | 잠금 상태에서 thread.join() | 뮤텍스 외부에서 join |

---

## 참고사항

- Flutter TextureRegistrar의 `MarkTextureFrameAvailable`은 **스레드 안전**
- Pigeon API 콜백은 **플랫폼 스레드에서만** 호출 가능
- 멀티 스레드 환경에서 공유 리소스는 항상 스레드 안전성 검토 필요

---

*작성일: 2026-01-19*
