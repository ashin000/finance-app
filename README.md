# Pay Voice AI

Flutter app with GitHub Actions for Android release builds and Firebase Hosting.

## GitHub Actions deployment

The workflow in `.github/workflows/deploy.yml` runs on pushes to `main` or `master`,
and can also be started manually from the Actions tab. It runs the Flutter tests,
builds an Android APK and App Bundle, uploads both as a workflow artifact, and
deploys the Flutter web build to Firebase Hosting for project `voiceai-3338c`.

### Firebase Hosting setup

Add a GitHub Actions repository secret named `FIREBASE_SERVICE_ACCOUNT`. Its value
must be the JSON key for a Google Cloud service account with permission to deploy
to Firebase Hosting (the Firebase Hosting Admin role is sufficient for the deploy).
Then push to `main`/`master`, or run **Build and deploy** manually in GitHub Actions.
The deployed URL is shown in the deployment job output.

### Android signing (for Play Store releases)

Android artifacts are built even when signing secrets are absent; in that case the
existing Gradle configuration falls back to the debug signing key. That output is
useful for testing, but is not suitable for publishing to Google Play. To sign with
your upload keystore, add these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file.
- `ANDROID_KEY_ALIAS`: Keystore alias.
- `ANDROID_KEY_PASSWORD`: Key password.
- `ANDROID_STORE_PASSWORD`: Keystore password.

With these secrets configured, the workflow signs the APK and App Bundle using
that keystore. Keep the keystore and its passwords private; do not commit them.

## Run locally

Install the Flutter SDK, then run `flutter pub get` followed by `flutter run`.
To run tests, use `flutter test`.
