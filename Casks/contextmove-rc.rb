# ContextMove — release-candidate cask.
#
# Deliberately a SEPARATE token from `contextmove`, not a newer version of it.
# Testers install this one; everybody else keeps installing the stable cask and
# never sees a release candidate. Nothing here touches `contextmove.rb`.
#
#     brew install --cask context-move/tap/contextmove-rc
#
# The url points at a GitHub *prerelease*, which is excluded from
# /releases/latest — so the in-app updater, the website download button and the
# stable cask's livecheck all carry on seeing the last stable release.
#
# Delete this file once the candidate ships (or is abandoned). A test cask left
# lying in a public tap is a trap for whoever finds it next.

cask "contextmove-rc" do
  version "4.5.0-rc1"
  sha256 "f2a0361614f8c9f57514b8315a88a8860f0345bba20bbbb5c38f614d9ea35ae9"

  url "https://github.com/Context-Move/ContextMove/releases/download/v#{version}/ContextMove-4.5.0-macOS.dmg",
      verified: "github.com/Context-Move/ContextMove/"
  name "ContextMove (release candidate)"
  desc "Local-first conversation context manager with MCP support"
  homepage "https://contextmove.com"

  # No livecheck: a release candidate is pinned on purpose.

  depends_on macos: ">= :big_sur" # matches LSMinimumSystemVersion 11.0

  # Refuse to sit alongside the stable cask — both install ContextMove.app to
  # the same path, and whichever landed second would silently own it.
  conflicts_with cask: "contextmove"

  app "ContextMove.app"

  # Ad-hoc signed, not notarized. Stripping quarantine on install is what lets
  # the app launch without the Gatekeeper "unidentified developer" block, and
  # verifying that it does is half the reason to test through a cask at all.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/ContextMove.app"]
  end

  # `brew uninstall --cask --zap contextmove-rc` removes the vault too.
  zap trash: [
    "~/Library/Application Support/ContextMove",
    "~/Library/Application Support/ContextVolt",
    "~/Library/Logs/ContextMove",
  ]
end
