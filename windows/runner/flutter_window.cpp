#include "flutter_window.h"

#include <optional>

#include <flutter/plugin_registrar_windows.h>
#include "flutter/generated_plugin_registrant.h"

#ifdef NATIVE_VIDEO_ENABLED
#include "native_video_api.g.h"
#include "native_video_handler.h"
#endif

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

#ifdef NATIVE_VIDEO_ENABLED
  // Initialize Native Video Handler for high-performance video streaming
  // Get plugin registrar for texture and messenger access
  auto registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(
          flutter_controller_->engine()->GetRegistrarForPlugin("NativeVideoHandler"));

  native_video_handler_ = std::make_unique<NativeVideoHandler>(
      registrar->texture_registrar(),
      registrar->messenger());

  // Set window handle for thread-safe callbacks
  native_video_handler_->SetHwnd(GetHandle());

  NativeVideoHostApi::SetUp(
      registrar->messenger(),
      native_video_handler_.get());
#endif

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
#ifdef NATIVE_VIDEO_ENABLED
    case WM_NATIVE_VIDEO_FRAME:
      if (native_video_handler_) {
        auto* data = reinterpret_cast<FrameCallbackData*>(lparam);
        native_video_handler_->ProcessFrameCallback(data);
      }
      return 0;
#endif
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
