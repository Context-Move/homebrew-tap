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
  version "4.1.1"
  sha256 "f934496dbfedca3bc2b2ce4f6393d14ce60efa610ba4dd17eb70a919fb5112df"

  # Points at the public distribution repo, not the private source repo — a
  # cask URL has to be fetchable anonymously by every `brew install`.
  url "https://github.com/Rithvickkr/contextmove/releases/download/v#{version}/ContextMove-#{version}-macOS.dmg",
      verified: "github.com/Rithvickkr/contextmove/"
  name "ContextMove"
  desc "Local-first conversation context manager with MCP support"
  homepage "https://github.com/Rithvickkr/contextmove"

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
  zap trash: [
    "~/Library/Application Support/ContextVolt",
    "~/Library/Saved Application State/com.contextvolt.app.savedState",
  ]

  caveats <<~EOS
    ContextMove stores its database, config, and logs in:
      ~/Library/Application Support/ContextVolt

    No AI models are downloaded — capture, summarization, and search all run
    without one, so the app opens straight into your workspace on first launch.

    To capture conversations, install the browser extension: open ContextMove
    and follow the first-run tour, or load the bundled extension/ folder as an
    unpacked extension in any Chromium browser.
  EOS
end
