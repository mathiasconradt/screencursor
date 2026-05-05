cask "screen-cursor" do
  version "1.0.4"
  sha256 "67aba0003d68e9f03d08557c15f93de6110d7de94aecfe9451af948867423e27"

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
