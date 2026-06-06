# Android release to Google Play — CI setup

The workflow [`android-release.yml`](workflows/android-release.yml) builds a signed
AAB and uploads it to the Play **internal** track on every push to `develop`.

Do all of the following **before** pushing, or the first run will fail.

## 1. Upload keystore

The app is already on Play with **Play App Signing**, so uploads must be signed
with the existing **upload key** (alias `upload`). Its certificate fingerprint is:

```
SHA-1: B3:8E:A1:FA:68:01:AE:A5:5F:02:71:43:51:50:FC:11:16:4A:39:5C
```

Verify any keystore you find matches:

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload   # compare SHA1
```

If the keystore is lost, do an **upload key reset** in Play Console
(Setup → App integrity) — that does NOT affect already-installed users because
Google holds the app signing key.

## 2. GitHub Actions secrets

Settings → Secrets and variables → Actions → **New repository secret**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore store password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | full JSON from step 3 |

## 3. Google Play service account (for automated upload)

1. Play Console → **Setup → API access** → link/create a Google Cloud project.
2. In Google Cloud Console → **IAM & Admin → Service Accounts** → create one →
   **Keys → Add key → JSON** → download. Paste the JSON into
   `PLAY_SERVICE_ACCOUNT_JSON`.
3. Back in Play Console → **Users and permissions** → invite the service-account
   email → grant **Release to testing tracks** (at least) for this app.
4. First upload of a NEW app sometimes must be done **manually** in the Play UI
   before the API will accept uploads — since this app is already released, the
   API path should work directly.

## 4. versionCode offset

Play requires strictly increasing `versionCode`. The workflow computes:

```
versionCode = VERSION_CODE_OFFSET + github.run_number
```

Set `VERSION_CODE_OFFSET` in the workflow `env:` so the first CI build exceeds
the **highest versionCode already live on Play** (check Play Console →
production/testing releases). Default is `100`.

## 5. MSAL / Play App Signing check (auth correctness)

`android/app/build.gradle.kts` hard-codes a release MSAL redirect hash that
currently matches the **upload** certificate. If Play App Signing is enabled
(it is, for this app), the installed app is signed by **Google's app signing
key**, so the runtime MSAL hash differs.

Confirm in Play Console → Setup → **App integrity → App signing key certificate**:

- Get the **App signing key SHA-1**, compute its MSAL hash:
  ```bash
  # from the SHA-1 / DER cert Play shows you:
  openssl x509 -in app_signing_cert.der -inform DER -outform DER | openssl dgst -sha1 -binary | openssl base64
  ```
- The release `manifestPlaceholders["msalRedirectPath"]` must use **that** hash,
  and the same `msauth://company.thecloud.pantry/<hash>` redirect URI must be
  registered in the Entra ID app registration. Otherwise Microsoft login breaks
  in the Play build (builds fine, fails at login).
