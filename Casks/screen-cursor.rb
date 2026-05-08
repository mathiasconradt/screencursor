cask "screen-cursor" do
  version "1.0.6"
  sha256 "aabd8ddbdd2daa6b7999fa688c5f5346a0e5eba0c340f4c3d58e8435e78bda77"

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

  zap trash: "~/Library/Preferences/com.local.ScreenCursor.plist"
end
