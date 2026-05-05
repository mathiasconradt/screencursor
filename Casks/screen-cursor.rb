cask "screen-cursor" do
  version "1.0.0"
  sha256 "2cc6632848239e6488176377a8f1ec4d58cecffea2c118e7950d5f87bbdc2ad3"

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
