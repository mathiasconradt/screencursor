cask "screen-cursor" do
  version "1.0.11"
  sha256 "d98e382e2835e98ac3658928962e485f8363f50805762342835118edd9c9bf5f"

  url "https://github.com/mathiasconradt/screencursor/releases/download/v#{version}/Screen-Cursor-#{version}.zip"
  name "Screen Cursor"
  desc "Menu bar cursor highlight for macOS"
  homepage "https://github.com/mathiasconradt/screencursor"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "Screen Cursor.app"

  preflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{staged_path}/Screen Cursor.app"],
                   sudo: false
  end

  zap trash: "~/Library/Preferences/com.local.ScreenCursor.plist"
end
