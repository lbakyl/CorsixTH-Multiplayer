# Signing the macOS app (one-time setup)

Without a signature from an Apple developer, macOS refuses to open the
downloaded app the first time, and players have to find System Settings >
Privacy & Security > Open Anyway. With a Developer ID signature and Apple's
notarization (Apple scans the app and issues a ticket), the app opens with a
double click.

The workflow `.github/workflows/sign-macos.yml` does this for every release,
on GitHub's own Macs, with `scripts/multiplayer/sign_macos_app.sh`. It needs
two things from the Apple developer account, kept as GitHub secrets. Nobody
else needs access to the Apple account, and nobody can read the secrets back
from GitHub: workflows can only use them.

## 1. Apple Developer Program

Join at https://developer.apple.com/programs/ (99 USD a year). On a personal
account, macOS names the person as the developer; to show an organisation's
name, Apple wants a registered legal entity with a D-U-N-S number.

If the membership ends, apps signed and notarized before keep opening; new
releases cannot be signed until it is renewed.

## 2. The certificate ("Developer ID Application")

Only the account holder can make it. Easiest on a Mac with Xcode: Xcode >
Settings > Accounts > the Apple ID > Manage Certificates > + > Developer ID
Application. (Or on developer.apple.com > Certificates > +, with a request
made in Keychain Access > Certificate Assistant > Request a Certificate From a
Certificate Authority.)

Then in Keychain Access > My Certificates, right-click "Developer ID
Application: ..." (it must show its private key under it) > Export, as a
`.p12` file with a strong password. Make its text for GitHub:

    base64 -i DeveloperID.p12 | pbcopy

Keep the `.p12` and its password somewhere safe, such as a password manager.

## 3. The notarization key (App Store Connect API key)

https://appstoreconnect.apple.com > Users and Access > Integrations > App
Store Connect API > Team Keys > + (the first time the account holder may have
to click Request Access). Name it e.g. "OpenTH notarization", access
"Developer". Download the `AuthKey_XXXXXXXXXX.p8` file (Apple offers it only
once) and note the Key ID (in the list) and the Issuer ID (above the list).

## 4. GitHub (needs admin rights on openth-org/openth)

Settings > Environments > New environment, name `macos-signing`:

- Deployment branches and tags: Selected branches and tags > Add rule > Tag,
  pattern `mp-*`. Then only release tags can use the secrets, not a pushed
  branch.
- Optional: Required reviewers (e.g. yourself): every signing then waits for
  your click in the Actions tab.
- Environment secrets:

  | Name | Value |
  | --- | --- |
  | `MACOS_CERT_P12` | the base64 text of the `.p12` (step 2) |
  | `MACOS_CERT_PASSWORD` | its password |
  | `NOTARY_KEY_P8` | the whole text of the `.p8` file, all lines |
  | `NOTARY_KEY_ID` | the Key ID |
  | `NOTARY_ISSUER_ID` | the Issuer ID |

Then Settings > Secrets and variables > Actions > Variables > New repository
variable: `MACOS_SIGNING` = `on`. (Until then, releases are not signed and the
workflow does nothing.)

## What happens then

When a release is published, the workflow waits up to 4 hours for its macOS
zip, signs every library, Lua module and the app with the certificate and the
hardened runtime, has Apple notarize it, staples the ticket to the app, runs
the smoke tests, and replaces the zip on the release with the signed one (the
SHA-256 in the release notes is updated). The signed zip is also kept as the
run's artifact.

By hand (Actions > macOS signing > Run workflow, "Use workflow from" the
release's tag; "publish" off keeps the signed zip only as an artifact), for
example when a macOS zip was uploaded again later. GitHub offers this button
only once the workflow is on the default branch (master).

The certificate must never go to a self-hosted runner such as Iris's Mac:
anything running on that machine could read it. The signing job asks for
`macos-26`, one of GitHub's own machines (Iris's Mac has the labels
`self-hosted` and `macos-27`), and stops at once if it finds itself anywhere
else. So never give a self-hosted runner the label `macos-26`.

If the certificate or the key ever leaks: revoke it on developer.apple.com
(or App Store Connect for the key), make a new one and replace the secrets.

A change to the workflow or the script on mp/team-hospitals runs a test
without any secret: an ad hoc signature with the hardened runtime (and
library validation switched off, as an ad hoc signature has no team) of the
newest release's macOS zip, then the smoke tests.
