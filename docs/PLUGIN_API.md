# Plugin API — Content Source Plugins

## 1. Scope

Plugin v1 is only for content sources.

It is not a general application plugin framework.

## 2. Why not downloadable Dart code

Flutter release apps use AOT-compiled Dart. External source plugins therefore must not depend on downloading new Dart application code.

Use:
- manifest
- constrained JavaScript/script runtime
- optional future declarative rules

The host is Dart; runtime implementation may use a platform adapter when needed.

## 3. Package

```text
plugin/
  manifest.json
  main.js
  icon.png
  fixtures/        # development package only, optional
```

## 4. Manifest

Minimum fields:

```json
{
  "id": "io.example.source",
  "name": "Example",
  "version": "1.0.0",
  "apiVersion": "1",
  "minimumAppVersion": "1.0.0",
  "author": "Example",
  "description": "Example source",
  "contentKinds": ["novel"],
  "permissions": {
    "networkDomains": ["example.com"],
    "cookies": true,
    "storage": true
  }
}
```

Plugin version and Plugin API version are different concepts.

## 5. Host APIs

Initial host surface:

- `http.get`
- `http.post`
- `cookies.get/set/clear`
- `html.parse/query`
- `storage.get/set/remove`
- `log.debug/info/warn/error`

No arbitrary filesystem.

No arbitrary native APIs.

No UI injection.

## 6. Source functions

A plugin may implement capability-gated functions:
- search
- explore
- book detail
- volume/chapter list
- chapter content
- authentication
- filter metadata
- image request transformation

Plugin output is validated and normalized into Source domain models.

## 7. Permissions

Least privilege.

Network host must reject undeclared domains.

Plugin storage is namespaced by plugin ID.

Cookie access is source/plugin scoped.

## 8. Failure isolation

Handle:
- invalid JSON manifest
- API version mismatch
- script syntax error
- timeout
- cancellation
- invalid return shape
- parser error
- network error
- permission denial
- excessive resource use

Plugin failure must surface as a normal Source failure.

## 9. Diagnostics

Every plugin execution gets:
- pluginId
- function
- execution/request ID
- duration
- cancellation state

Never log credentials/cookie values.

## 10. Development experience

Target workflow:

```text
clone template
edit manifest/main.js
run fixture tests
package
install
```

Normal source development should not require:
- Xcode
- Swift
- Kotlin
- Gradle

## 11. API compatibility

Breaking Plugin API changes require:
- version bump
- documented migration
- compatibility checks before execution

Never silently execute incompatible plugins.

## 12. Security boundary

Treat plugins as untrusted content logic.

The runtime must not assume plugin authors are trusted merely because a plugin was installed manually.
