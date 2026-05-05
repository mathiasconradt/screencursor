cask "screen-cursor" do
  version "1.0.1"
  sha256 "84b51f792dc0c67ebbe03b3958fbe5394cff4ecf822474a56132bab01e00ab71"

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
