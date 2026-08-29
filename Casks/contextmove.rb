# ContextMove — Homebrew Cask
#
# This file belongs in a SEPARATE GitHub repo named `homebrew-tap`, under a
# top-level `Casks/` directory:  Context-Move/homebrew-tap/Casks/contextmove.rb
# It is kept here in the main repo as the source of truth — see README.md in
# this folder for the one-time tap setup and the release update workflow.
#
# Users install with:
#     brew install --cask context-move/tap/contextmove
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
  version "4.6.0"
  sha256 "483694bb755a54fc5af51dcbcfc24f7cf03721e2138c42bac4a712bf84ad7777"

  # Points at the public distribution repo, not the private source repo — a
  # cask URL has to be fetchable anonymously by every `brew install`.
  url "https://github.com/Context-Move/ContextMove/releases/download/v#{version}/ContextMove-#{version}-macOS.dmg",
      verified: "github.com/Context-Move/ContextMove/"
  name "Context Move"
  desc "Local-first conversation context manager"
  homepage "https://github.com/Context-Move/ContextMove"

  livecheck do
    url :url
    strategy :github_latest
  end

  # No `depends_on formula: "ollama"`. Earlier versions ran a local LLM for
  # summaries and titles; 3.x builds them deterministically instead, so the app
  # downloads and runs no models at all. Keeping the dependency would have
  # forced a multi-hundred-MB install of a runtime nothing calls.

  # The .dmg is Apple Silicon only: build-mac.yml runs on the macos-14 runner,
  # and py2app freezes whatever arch that interpreter is, so the bundle carries
  # arm64 slices and nothing else. Without this guard `brew install` on an Intel
  # Mac SUCCEEDS and then the app refuses to launch — the user is told the
  # install worked and left with a dead icon and no reason for it. Rosetta does
  # not help; it translates x86_64 for Apple Silicon, not the other way around.
  #
  # Safe for Apple Silicon users running an Intel Homebrew under /usr/local:
  # Homebrew checks Hardware::CPU.type, which reads `sysctl hw.cputype`, and
  # that reports the PHYSICAL cpu — sysctl does not lie under Rosetta 2 (it is
  # how Homebrew detects Rosetta in the first place, by diffing sysctl against
  # uname). So those installs still see :arm and still pass.
  depends_on arch: :arm64
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

    To capture conversations, install the browser extension from the Chrome
    Web Store — ContextMove opens the listing for you at the end of the
    first-run tour:
      https://chromewebstore.google.com/detail/goenplhbbljlodllpclonganogjajppe

    A copy also ships inside the app, for a browser without the store or to
    run a build newer than the published one:
      ContextMove.app/Contents/Resources/extension
    Load it with Developer mode > Load unpacked. Use one or the other — with
    both installed every chat page gets two panels.
  EOS
end
