cask "screen-cursor" do
  version "1.0.14"
  sha256 "ae7d9029668677d771c21fb5bb92e2ac66b8c11c679620a10febcfd1b10a4fbb"

  url "https://github.com/mathiasconradt/screencursor/releases/download/v#{version}/Screen-Cursor-#{version}.zip"
  name "Screen Cursor"
  desc "Menu bar cursor highlight for macOS"
  homepage "https://github.com/mathiasconradt/screencursor"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "Screen Cursor.app"

  preflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{staged_path}}/Screen Cursor.app"]
  end

  zap trash: "~/Library/Preferences/com.local.ScreenCursor.plist"
end
