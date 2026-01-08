# iScan Live Viewer

ZeroMQ 기반 카메라 스트리밍 데스크톱 애플리케이션

## 개요

iScan Live Viewer는 ZeroMQ 프로토콜을 사용하여 다중 카메라 영상을 실시간으로 수신하고 표시하는 Flutter Windows 데스크톱 애플리케이션입니다.

## 주요 기능

- 다중 카메라 실시간 스트리밍 뷰어
- ZeroMQ를 통한 고성능 영상 수신
- 깔끔한 타일 기반 카메라 레이아웃

## 기술 스택

- **프레임워크**: Flutter (Windows Desktop)
- **상태관리**: Riverpod
- **데이터 클래스**: Freezed
- **라우팅**: Go Router
- **통신**: DartZMQ (ZeroMQ)
- **인스톨러**: Inno Setup

## 프로젝트 구조

```
lib/
├── core/           # 앱 설정, 상수, 라우터
├── data/           # 레포지토리 구현체
├── domain/         # 엔티티, 레포지토리 인터페이스
├── infrastructure/ # ZeroMQ 클라이언트
└── presentation/   # UI (페이지, 뷰모델, 위젯)
```

## 시작하기

### 요구 사항

- Flutter SDK 3.10.4 이상
- Windows 개발 환경

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run -d windows
```

### 빌드

```bash
# Windows 릴리즈 빌드
flutter build windows --release
```

### 인스톨러 생성

Inno Setup이 설치되어 있어야 합니다.

```bash
# installer.iss 파일로 인스톨러 생성
iscc installer.iss
```

## 브랜치 네이밍 규칙

이슈와 관련된 작업 시 다음 규칙을 따릅니다:

| 유형 | 브랜치명 형식 | 예시 |
|------|--------------|------|
| 버그 수정 | `fix/#이슈번호-간단한-설명` | `fix/#12-로그인-오류-수정` |
| 새 기능 | `feat/#이슈번호-간단한-설명` | `feat/#5-다크모드-추가` |
| 문서 | `docs/#이슈번호-간단한-설명` | `docs/#8-README-업데이트` |
| 리팩토링 | `refactor/#이슈번호-간단한-설명` | `refactor/#15-코드-정리` |

## 라이선스

비공개 프로젝트
