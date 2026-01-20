# ZMQ Stream Header Format

## Message Structure

ZMQ 메시지는 다음과 같은 바이너리 구조로 전송됩니다:

```
+------------------+------------------+------------------+
| Header Length    | JSON Header      | JPEG Image Data  |
| (4 bytes)        | (variable)       | (variable)       |
+------------------+------------------+------------------+
```

### 1. Header Length (4 bytes)
- Little-endian uint32
- JSON 헤더의 바이트 길이

### 2. JSON Header (variable)
- UTF-8 인코딩된 JSON 문자열
- 중첩된 구조 사용

### 3. JPEG Image Data (variable)
- 압축된 JPEG 이미지 데이터

---

## JSON Header Structure

```json
{
  "header": {
    "cam_idx": "top_1",
    "cam_num": "1",
    "brightness": 51.7,
    "motion": true,
    "bbox": {
      "x": "284",
      "y": "0",
      "w": "712",
      "h": "480"
    }
  }
}
```

### Fields

| Field | Type | Description | Dart Type |
|-------|------|-------------|-----------|
| `header` | object | 모든 헤더 정보를 담는 wrapper 객체 | - |
| `header.cam_idx` | string | 카메라 식별자 (예: "top_1", "top_2", "btm_1", "btm_2") | `String?` |
| `header.cam_num` | string | 카메라 번호 | `String?` |
| `header.brightness` | number | 밝기 값 (0.0 ~ 100.0) | `double?` |
| `header.motion` | boolean | 모션 감지 여부 | `bool?` |
| `header.bbox` | object | 바운딩 박스 정보 (optional) | - |
| `header.bbox.x` | string | X 좌표 | `int?` (bboxX) |
| `header.bbox.y` | string | Y 좌표 | `int?` (bboxY) |
| `header.bbox.w` | string | 너비 | `int?` (bboxW) |
| `header.bbox.h` | string | 높이 | `int?` (bboxH) |

> **Note:** bbox 값은 JSON에서 string으로 전달되지만 Dart에서 int로 변환됩니다.
> `bboxString` getter를 사용하면 `"712x480+284+0"` 형식으로 출력됩니다.

---

## UI에서 표시되는 헤더 포맷

멀티스트림 패널의 "헤더 보기" 메뉴에서 표시되는 JSON 포맷:

```json
{
  "cam_idx": "top_1",
  "cam_num": "1",
  "brightness": 51.7,
  "motion": true,
  "bbox": {
    "x": 284,
    "y": 0,
    "w": 712,
    "h": 480
  }
}
```

> **Note:** UI에서는 내부 `header` wrapper 없이 직접 필드들이 표시됩니다.
> bbox 값은 int로 변환되어 표시됩니다.

---

## Port Mapping

| Port | Channel | Description |
|------|---------|-------------|
| 17001 | CAM1 | 기본 카메라 1 |
| 17002 | CAM2 | 기본 카메라 2 |
| 17004 | CAM3 | 추가 카메라 3 |
| 17005 | CAM4 | 추가 카메라 4 |

> Note: 17003 포트는 사용하지 않음

---

## Parsing Flow (C++)

```
1. ZMQ 메시지 수신
2. 첫 4바이트에서 header_len 추출 (little-endian)
3. header_len 유효성 검사:
   - > 1MB 또는 0 또는 메시지 크기 초과 → Raw JPEG로 처리
   - 그 외 → JSON 헤더 파싱
4. JSON에서 "header" 객체 추출 (중첩 구조)
5. 내부 필드 파싱: cam_idx, cam_num, brightness, motion
6. 나머지 데이터를 JPEG으로 디코딩
```

---

## Example Code (Dart)

```dart
/// 프레임 파싱: [4바이트 헤더길이][JSON헤더][이미지데이터]
ZmqFrame? _parseFrame(Uint8List raw) {
  if (raw.length < 4) return null;

  // Little-endian 헤더 길이
  final headerLen = raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24);
  if (raw.length < 4 + headerLen) return null;

  // JSON 헤더 파싱
  final headerBytes = raw.sublist(4, 4 + headerLen);
  final headerStr = utf8.decode(headerBytes);
  final json = jsonDecode(headerStr) as Map<String, dynamic>;

  // 중첩된 header 객체에서 값 추출
  final header = json['header'] as Map<String, dynamic>?;
  final camIdx = header?['cam_idx'];
  final brightness = header?['brightness'];

  // 이미지 데이터 추출
  final imageData = Uint8List.sublistView(raw, 4 + headerLen);

  return ZmqFrame(header: header ?? {}, imageData: imageData);
}
```

---

## Related Files

- `windows/runner/native_video_handler.cpp` - C++ 파싱 구현
- `lib/infrastructure/zmq/zmq_client.dart` - Dart 파싱 구현
- `lib/domain/entities/multi_stream_entities.dart` - StreamInfo 엔티티
- `lib/domain/services/multi_stream_service.dart` - 멀티스트림 서비스
