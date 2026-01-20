# 앱 안정성 개선 보고서

## 개요

앱 빠른 종료/재시작 시 크래시 문제와 로컬 저장소 기능 구현에 대한 문서입니다.

---

## 1. 앱 종료 시 크래시 문제

### 문제 상황
- 앱을 빠르게 껐다 켜면 크래시 발생
- 이전 인스턴스의 네이티브 리소스가 완전히 정리되기 전에 새 인스턴스 시작

### 원인 분석
1. **네이티브 스레드 정리 지연**: ZMQ 수신 스레드가 블로킹 상태에서 즉시 종료되지 않음
2. **리소스 정리 순서 문제**: 소켓, 컨텍스트, 스레드 정리 순서가 비효율적
3. **Null 체크 누락**: 소켓 닫힌 후에도 접근 시도

### 해결책

#### C++ 소멸자 개선 (`native_video_handler.cpp`)

**기존 코드:**
```cpp
NativeVideoHandler::~NativeVideoHandler() {
  for (int64_t key : keys) {
    CleanupStream(key);  // 각 스트림 개별 정리 (느림)
  }
}
```

**수정 코드:**
```cpp
NativeVideoHandler::~NativeVideoHandler() {
  // Step 1: 모든 스트림 정지 플래그 설정
  for (auto& pair : streams_) {
    pair.second->is_running = false;
  }

  // Step 2: 모든 ZMQ 소켓 닫기 (스레드 언블록)
  for (auto& pair : streams_) {
    if (stream->zmq_socket) {
      zmq_close(stream->zmq_socket);
      stream->zmq_socket = nullptr;
    }
  }

  // Step 3: 모든 스레드 조인 (이제 빠르게 종료됨)
  for (auto& t : threads_to_join) {
    t.join();
  }

  // Step 4: 나머지 리소스 정리
  // zmq_context, texture, tj_handle 등
}
```

#### ReceiveLoop 방어 코드 추가

```cpp
while (stream->is_running && stream->zmq_socket != nullptr) {
  void* socket = stream->zmq_socket;
  if (socket == nullptr) break;

  int size = zmq_recv(socket, recv_buffer.data(), recv_buffer.size(), 0);

  if (size == -1) {
    int err = zmq_errno();
    if (err == ETERM || err == ENOTSOCK) {
      // 소켓이 닫혔으면 즉시 종료
      break;
    }
  }

  // 프레임 처리 전 is_running 체크
  if (stream->is_running && DecodeJpeg(...)) {
    if (texture_registrar_ && stream->texture_id >= 0) {
      texture_registrar_->MarkTextureFrameAvailable(stream->texture_id);
    }
  }
}
```

---

## 2. 로컬 저장소 구현

### 목적
- 카메라 주소와 채널 수를 앱 재시작 후에도 유지

### 구현 파일

#### `lib/infrastructure/local_storage/shared_preferences.dart`
```dart
@Riverpod(keepAlive: true)
sp.SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('must be overridden in main');
}
```

#### `lib/infrastructure/local_storage/camera_settings.dart`
```dart
/// 저장소 키
class CameraSettingsKeys {
  static const String cameraCount = 'camera_count';
  static String cameraAddress(int id) => 'camera_address_$id';
}

/// 카메라 갯수 설정
@Riverpod(keepAlive: true)
class CameraCountSetting extends _$CameraCountSetting {
  @override
  int build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getInt(CameraSettingsKeys.cameraCount) ?? 2;
    } catch (e) {
      return 2;  // 기본값
    }
  }

  Future<void> set(int count) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(CameraSettingsKeys.cameraCount, count);
      state = count;
    } catch (e) {
      state = count;  // 저장 실패해도 상태 업데이트
    }
  }
}

/// 카메라 주소 설정
@Riverpod(keepAlive: true)
class CameraAddressSetting extends _$CameraAddressSetting {
  @override
  String build(int id) {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(CameraSettingsKeys.cameraAddress(id));
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      // 기본값 반환
    }
    return defaultCameraAddresses[id];
  }

  Future<void> set(String address) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(CameraSettingsKeys.cameraAddress(id), address);
      state = address;
    } catch (e) {
      state = address;
    }
  }
}
```

#### `lib/main.dart` 초기화
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const IScanLiveViewerApp(),
    ),
  );
}
```

### 방어 코드
- 모든 SharedPreferences 접근에 try-catch 추가
- 예외 발생 시 기본값 반환하여 앱 크래시 방지

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `windows/runner/native_video_handler.cpp` | C++ 네이티브 핸들러 (소멸자, ReceiveLoop 개선) |
| `lib/infrastructure/local_storage/shared_preferences.dart` | SharedPreferences 프로바이더 |
| `lib/infrastructure/local_storage/camera_settings.dart` | 카메라 설정 저장/로드 |
| `lib/main.dart` | 앱 초기화 (SharedPreferences 오버라이드) |
| `lib/presentation/viewmodels/camera_viewmodel.dart` | 저장소 연동 |

---

## 테스트 결과

- [x] 앱 빠른 종료/재시작 크래시 해결
- [x] 카메라 주소 변경 후 앱 재시작 시 유지
- [x] 카메라 채널 수 변경 후 앱 재시작 시 유지
