# Lend Tracker

A local-first Flutter application for recording money lent to or borrowed from
device contacts. Transactions and settings are stored in AES-encrypted Hive
boxes; the encryption key and salted app-PIN hash are kept in platform secure
storage.

## Application flow

`Splash → PIN setup/unlock → Home / Connect / Settings`

- **Home** shows the current month's balance and all transactions.
- **Connect** reads device contacts and opens contact transaction histories.
- **Settings** manages the app PIN, biometric availability, and currency.

The application has no remote API or server database.

## Structure

- `lib/data/` — Hive and secure-storage repositories
- `lib/model/` — persisted transaction model and generated adapter
- `lib/screen/` — application screens and navigation
- `lib/utils/` — formatting, validation, contact identity, and theme helpers
- `lib/widget/` — reusable presentation components
- `test/` — repository and business-rule regression tests

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Generated Hive adapters are updated with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Android biometric authentication requires `FlutterFragmentActivity` and an
AppCompat theme; both are configured in the Android runner. Face ID usage is
declared in the iOS `Info.plist`.
