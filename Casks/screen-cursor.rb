cask "screen-cursor" do
  version "1.0.8"
  sha256 "8e9360a23e2bc5fdff3428224177fe08894f0cad2a153c2b0e3c9133c6376f71"

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
