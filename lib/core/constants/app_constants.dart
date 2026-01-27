/// 기본 카메라 주소 설정
///
/// 지원 형식:
/// - ZMQ: tcp://IP:PORT (예: tcp://192.168.0.100:17002)
/// - HTTP MJPEG: http://IP:PORT/livecam/mjpeg?cam=CAM_ID
///   - cam 파라미터: left, right, top_1, top_2, single_1, single_2, ...
const List<String> defaultCameraAddresses = [
  'tcp://221.146.86.129:17002',
  'http://58.238.37.52:18081/livecam/mjpeg?cam=left',
  'http://58.238.37.52:18081/livecam/mjpeg?cam=right',
  'http://58.238.37.52:18081/livecam/mjpeg?cam=single_1',
];

/// 최대 로그 개수
const int maxLogCount = 50;

/// FPS 업데이트 간격 (ms)
const int fpsUpdateIntervalMs = 1000;

/// 수신 타임아웃 (초) - 이 시간 동안 프레임이 없으면 수신 불가로 판단
const int receiveTimeoutSeconds = 3;
