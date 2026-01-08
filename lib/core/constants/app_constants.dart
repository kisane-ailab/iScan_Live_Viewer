/// 기본 카메라 주소 설정
const List<String> defaultCameraAddresses = [
  'tcp://221.146.86.129:17002',
  'tcp://58.238.37.52:17002',
  'tcp://58.238.37.52:17003',
  'tcp://58.238.37.52:17004',
];

/// 최대 로그 개수
const int maxLogCount = 50;

/// FPS 업데이트 간격 (ms)
const int fpsUpdateIntervalMs = 1000;

/// 수신 타임아웃 (초) - 이 시간 동안 프레임이 없으면 수신 불가로 판단
const int receiveTimeoutSeconds = 3;
