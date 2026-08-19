# ContextMove — Homebrew Cask
#
# This file belongs in a SEPARATE GitHub repo named `homebrew-tap`, under a
# top-level `Casks/` directory:  Rithvickkr/homebrew-tap/Casks/contextmove.rb
# It is kept here in the main repo as the source of truth — see README.md in
# this folder for the one-time tap setup and the release update workflow.
#
# Users install with:
#     brew install --cask rithvickkr/tap/contextmove
#
# This is the RECOMMENDED macOS install path, not an alternative to the .dmg.
# The app is ad-hoc signed rather than notarized (no paid Apple Developer ID),
# so a direct .dmg download makes every user walk through Gatekeeper's
# "unidentified developer" block by hand. The postflight below strips the
# quarantine attribute, so a cask install just launches.
#
# Run installer/homebrew/update_cask.sh <version> against the published release
# on every version bump — it fills in both version and sha256. A stale digest
# makes `brew install` fail with a checksum mismatch, which reads to the user
# like a corrupted download rather than a packaging mistake.

cask "contextmove" do
  version "4.3.0"
  sha256 "f8e00558c6a3bbded1d3b0fa82f781974339a3ce1556079b7e1709747b09e4d3"

  # Points at the public distribution repo, not the private source repo — a
  # cask URL has to be fetchable anonymously by every `brew install`.
  url "https://github.com/Rithvickkr/ContextMove/releases/download/v#{version}/ContextMove-#{version}-macOS.dmg",
      verified: "github.com/Rithvickkr/ContextMove/"
  name "ContextMove"
  desc "Local-first conversation context manager with MCP support"
  homepage "https://github.com/Rithvickkr/ContextMove"

  livecheck do
    url :url
    strategy :github_latest
  end

  # No `depends_on formula: "ollama"`. Earlier versions ran a local LLM for
  # summaries and titles; 3.x builds them deterministically instead, so the app
  # downloads and runs no models at all. Keeping the dependency would have
  # forced a multi-hundred-MB install of a runtime nothing calls.
  depends_on macos: ">= :big_sur" # matches LSMinimumSystemVersion 11.0

  app "ContextMove.app"

  # The .app is ad-hoc signed, not notarized (no paid Apple Developer ID).
  # Stripping the quarantine attribute on install lets it launch without the
  # Gatekeeper "unidentified developer" prompt — the standard pattern for
  # unsigned apps distributed through a personal tap.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/ContextMove.app"]
  end

  # `brew uninstall --zap contextmove` removes user data too.
  # Both names are listed: installs from before the ContextVolt -> ContextMove
  # rename may still hold either, and a zap that misses one leaves the vault
  # behind on an uninstall the user asked to be complete.
  zap trash: [
    "~/Library/Application Support/ContextMove",
    "~/Library/Application Support/ContextVolt",
    "~/Library/Saved Application State/com.contextmove.app.savedState",
    "~/Library/Saved Application State/com.contextvolt.app.savedState",
  ]

  caveats <<~EOS
    ContextMove stores its database, config, and logs in:
      ~/Library/Application Support/ContextMove

    No AI models are downloaded — capture, summarization, and search all run
    without one, so the app opens straight into your workspace on first launch.

    To capture conversations, install the browser extension: open ContextMove
    and follow the first-run tour, or load the bundled extension/ folder as an
    unpacked extension in any Chromium browser.
  EOS
end
