cask "screen-cursor" do
  version "1.0.12"
  sha256 "d13a306ccc6c2eb6320a1be7cf996c4d93bde6cdff0ff14e5a6f9306113a859f"

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

  preflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{staged_path}/Screen Cursor.app"],
                   sudo: false
  end

  zap trash: "~/Library/Preferences/com.local.ScreenCursor.plist"
end
