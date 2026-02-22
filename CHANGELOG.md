## 0.0.5

* Improved pub.dev page for better discoverability: rewrote `description` in `pubspec.yaml` to a keyword-rich one-liner.
* Added `topics` (`supabase`, `authentication`, `database`, `storage`, `realtime`) to `pubspec.yaml` for pub.dev topic filtering.
* Added `issue_tracker` URL to `pubspec.yaml`.
* Rewrote `README.md` with pub/likes/points/license/platform badges, a "Why supabase\_easy?" comparison table, full code examples for all new v0.0.4 APIs (`deleteMany`, `updateWhere`, `signInWithOtp`, `verifyOtp`, `EasyException`, `TransformOptions`), a quick API-reference table, and collapsible OAuth/Storage setup sections.
* Updated install snippet in `README.md` to `^0.0.4`.

## 0.0.4

* **New `EasyException`** — unified error type wrapping `PostgrestException`, `AuthException`, and `StorageException`. All public APIs now throw `EasyException` instead of raw Supabase exceptions.
* **`EasyRepository`**: fixed `count()` to project only `id` instead of `*` (avoids fetching all row data); added `deleteMany(List<String> ids)` and `updateWhere({filter, data})` bulk operations; `stream()` now accepts optional `orderBy` / `ascending` parameters; all methods wrap errors in `EasyException`.
* **`EasyStorage`**: fixed `getPublicUrl` — `transform` parameter was silently ignored (dead-code bug); now correctly passes `TransformOptions` to the Supabase SDK; all methods wrap storage errors in `EasyException`.
* **`EasyAuth`**: added `signInWithOtp` (magic link / OTP email) and `verifyOtp`; added `isSignedIn` convenience getter; all methods wrap auth errors in `EasyException`.
* **`SupabaseEasyClient`**: added `isInitialized` getter; init-guard now throws a typed `EasyException` instead of a plain `Exception`.
* **`SupabaseEasy`**: removed bare `library;` directive; exposed `SupabaseEasy.isInitialized`; private constructor added (not meant to be instantiated); private constructor prevents accidental instantiation.
* **Exports**: added `EasyException`, `AuthException`, `StorageException`, `PostgrestException`, `AuthResponse`, `UserResponse`, `OtpType`, `CountOption`, `TransformOptions` to public barrel exports — users rarely need to import `supabase_flutter` directly.
* **`pubspec.yaml`**: removed unused `json_annotation`, `json_serializable`, and `build_runner` dependencies.
* **`analysis_options.yaml`**: tightened lint rules — `prefer_final_locals`, `unawaited_futures`, `avoid_catches_without_on_clauses`, `public_member_api_docs`, and more.

## 0.0.3

* Added `EasyStorage` for simplified file management (upload, download, delete, signed URLs).
* Added `signInWithOAuth` to `EasyAuth` for social login support.
* Added support for `FileOptions`, `SearchOptions`, and `FileObject` in storage operations.
* Improved library exports for easier integration.

## 0.0.2

* Updated documentation and README with screenshots.
* Improved package description for better discoverability.
* Refactored example app with a modern UI and modular structure.

## 0.0.1

* Initial release of `supabase_easy`.
* Added `EasyRepository` for simplified CRUD operations.
* Added `EasyAuth` for streamlined authentication.
* Added support for real-time streams in `EasyRepository`.
* Added `createMany`, `count`, and search functionality to `EasyRepository`.
* Added `updateUser` and `refreshSession` to `EasyAuth`.
* Comprehensive DartDoc documentation for all public APIs.
