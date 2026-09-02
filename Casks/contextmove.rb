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
  version "4.6.2"
  sha256 "1b87175eb1d370ecf6ec91aa331d77b64bc3ce0cd6d4cbf5d769f5e52a9251dd"

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

  # Quit before the .app is deleted. Safe to run on upgrade — which is exactly
  # when it matters, since `brew upgrade --cask` replaces the bundle underneath
  # whatever is running.
  #
  # Nothing else belongs in this stanza. `brew upgrade` and `brew reinstall`
  # both run `uninstall` before installing the new version, so anything that
  # cleared credentials or autostart here would sign the user out and turn
  # their launch-at-login off on every routine upgrade. That is the one place
  # macOS genuinely differs from Windows, where the updater installs over the
  # top and never invokes the uninstaller at all.
  uninstall quit: "com.contextmove.app"

  # `brew uninstall --zap contextmove` removes user data too. This is the
  # counterpart of answering Yes to the Windows uninstaller's "also delete your
  # conversations?" prompt: opt-in, and complete when opted into.
  #
  # Both names are listed throughout: installs from before the ContextVolt ->
  # ContextMove rename may still hold either, and a zap that misses one leaves
  # the vault behind on an uninstall the user asked to be complete.
  zap launchctl: "com.contextmove.autostart",
      trash:     [
        "~/Library/Application Support/ContextMove",
        "~/Library/Application Support/ContextVolt",
        "~/Library/Saved Application State/com.contextmove.app.savedState",
        "~/Library/Saved Application State/com.contextvolt.app.savedState",
        # Written at runtime by backend/autostart.py, not by the installer, so
        # nothing else would ever remove it. Left behind it points launchd at
        # an app that no longer exists.
        "~/Library/LaunchAgents/com.contextmove.autostart.plist",
      ],
      # Keychain items are not files, so `trash:` cannot reach them. Left in
      # place they are why a macOS reinstall comes back already signed in and
      # already connected to Drive — the same gap uninstall_cleanup.py closes
      # on Windows. Done here in plain shell rather than by calling that script
      # so it still works when the .app is broken, already gone, or was never
      # launched.
      #
      # machine_id is deliberately absent: entitlements.py binds a paid licence
      # to it, so clearing it would silently invalidate the entitlement of
      # anyone who reinstalls. It is a fingerprint, not a session.
      script:    {
        executable: "/bin/sh",
        args:       [
          "-c",
          "for s in ContextMove ContextVolt; do " \
          "for a in google_drive_refresh_token supabase_refresh_token supabase_profile; do " \
          "/usr/bin/security delete-generic-password -s \"$s\" -a \"$a\" >/dev/null 2>&1; " \
          "done; done; exit 0",
        ],
      }

  caveats <<~EOS
    ContextMove stores its database, config, and logs in:
      ~/Library/Application Support/ContextMove

    `brew uninstall` leaves all of that in place, along with your sign-in, so
    reinstalling picks up where you left off. To remove everything — vault,
    sign-in, and the Google Drive connection:
      brew uninstall --zap contextmove

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
