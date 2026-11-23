# Pinned CleanShot X 4.8.10 (last version before 5.x; matches the owned licence).
# Removed from upstream homebrew-cask history; installed by run_once_21-brew-bundle.
cask "cleanshot-4-8-10" do
  version "4.8.10"
  sha256 "0f1b1cdda9a93908ced0341abb0d505adc55e51d145562013085b1e70f366d84"

  url "https://updates.getcleanshot.com/v3/CleanShot-X-#{version}.dmg"
  name "CleanShot X"
  desc "Screen capturing tool (pinned to 4.8.10)"
  homepage "https://getcleanshot.com/"

  # No `auto_updates true`: keep brew from treating the app as self-updating.
  depends_on :macos

  app "CleanShot X.app"

  uninstall quit: "pl.maketheweb.cleanshotx"

  zap trash: [
    "~/Library/Application Support/CleanShot",
    "~/Library/Caches/pl.maketheweb.cleanshotx",
    "~/Library/Caches/SentryCrash/CleanShot X",
    "~/Library/Preferences/com.getcleanshot.app.plist",
    "~/Library/Preferences/pl.maketheweb.cleanshotx.plist",
  ]
end
