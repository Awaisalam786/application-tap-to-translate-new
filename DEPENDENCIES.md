# DEPENDENCIES.md
# German PDF Reader — Tap-to-Translate
# Verified Dependency License Registry

All licenses verified directly from source repositories and official documentation.

---

## Runtime Dependencies

### pdfrx
| Field | Value |
|---|---|
| **Package** | `pdfrx` |
| **Version** | `^2.6.5` |
| **Purpose** | PDF rendering, display, zoom/pan, text extraction with per-character bounding boxes |
| **License** | **MIT** |
| **License Text Verified** | ✅ Yes — from github.com/espresso3389/pdfrx/packages/pdfrx/LICENSE |
| **Copyright** | Copyright (c) 2018 @espresso3389 (Takashi Kawasaki) |
| **Commercial distribution** | ✅ Permitted — no restrictions |
| **Attribution in UI** | ❌ Not required in app UI |
| **Attribution in source** | ✅ Required — copyright notice must be included in all copies or substantial portions |
| **Source disclosure** | ❌ Not required |
| **Source URL** | https://github.com/espresso3389/pdfrx |

### pdfrx_engine
| Field | Value |
|---|---|
| **Package** | `pdfrx_engine` (transitive dependency of `pdfrx`) |
| **Version** | `^0.6.1` (pulled automatically by pdfrx) |
| **Purpose** | Low-level PDF parsing/rendering via PDFium; provides PdfPage, PdfPageText, charRects |
| **License** | **MIT** |
| **License Text Verified** | ✅ Yes — from github.com/espresso3389/pdfrx/packages/pdfrx_engine/LICENSE |
| **Copyright** | Copyright (c) 2018 @espresso3389 (Takashi Kawasaki) |
| **Commercial distribution** | ✅ Permitted |
| **Attribution in source** | ✅ Required — copyright notice in all copies |
| **Source disclosure** | ❌ Not required |

### pdfium_flutter
| Field | Value |
|---|---|
| **Package** | `pdfium_flutter` (transitive dependency) |
| **Version** | `^0.3.1` |
| **Purpose** | Bundles PDFium native binaries (Android via Dart native assets, iOS via CocoaPods) |
| **License** | **MIT** |
| **License Text Verified** | ✅ Yes — from github.com/espresso3389/pdfrx/packages/pdfium_flutter/LICENSE |
| **Copyright** | Copyright (c) 2025 @espresso3389 (Takashi Kawasaki) |
| **Commercial distribution** | ✅ Permitted |
| **Attribution in source** | ✅ Required |
| **Source disclosure** | ❌ Not required |

### PDFium (Google)
| Field | Value |
|---|---|
| **Component** | PDFium — C++ PDF engine bundled by pdfium_flutter |
| **Version** | Bundled by pdfrx_engine (Google's open-source PDFium, same as Chrome) |
| **Purpose** | Core PDF rendering, text extraction, coordinate system |
| **License** | **BSD 3-Clause** |
| **License Text Verified** | ✅ Yes — from pdfium.googlesource.com/pdfium/LICENSE |
| **Full License** | Copyright 2014 The PDFium Authors. All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that: (1) Redistributions of source code retain this notice. (2) Binary distributions reproduce this notice in documentation or materials provided with the distribution. (3) The name of Google Inc. may not be used to endorse derived products without specific prior permission. |
| **Commercial distribution** | ✅ Permitted |
| **Attribution in UI** | ❌ Not required in app UI |
| **Attribution required** | ✅ YES — "Copyright 2014 The PDFium Authors" must appear in binary distribution's documentation/materials (i.e., the app's Open Source Licenses screen) |
| **Source disclosure** | ❌ Not required (not copyleft) |

> **NOTE**: PDFium BSD 3-Clause attribution is REQUIRED in app credits. This is standard practice for all apps using Chromium-derived components.

---

### go_router
| Field | Value |
|---|---|
| **Package** | `go_router` |
| **Version** | `^14.0.0` |
| **Purpose** | Declarative routing and navigation |
| **License** | **BSD 3-Clause** (Flutter/Dart team) |
| **Commercial distribution** | ✅ Permitted |
| **Attribution in source** | ✅ Required |
| **Source URL** | https://pub.dev/packages/go_router |

### flutter_riverpod
| Field | Value |
|---|---|
| **Package** | `flutter_riverpod` |
| **Version** | `^2.0.0` |
| **Purpose** | State management |
| **License** | **MIT** |
| **Commercial distribution** | ✅ Permitted |
| **Attribution** | ✅ Required in source copies |
| **Source URL** | https://pub.dev/packages/flutter_riverpod |

### riverpod_annotation
| Field | Value |
|---|---|
| **Package** | `riverpod_annotation` |
| **Version** | `^2.0.0` |
| **Purpose** | Code generation annotations for Riverpod |
| **License** | **MIT** |
| **Commercial distribution** | ✅ Permitted |

### shared_preferences
| Field | Value |
|---|---|
| **Package** | `shared_preferences` |
| **Version** | `^2.0.0` |
| **Purpose** | Persistent key-value storage for reading position, settings |
| **License** | **BSD 3-Clause** (Flutter team) |
| **Commercial distribution** | ✅ Permitted |

### file_picker
| Field | Value |
|---|---|
| **Package** | `file_picker` |
| **Version** | `^8.0.0` |
| **Purpose** | PDF file selection from device storage |
| **License** | **MIT** |
| **Commercial distribution** | ✅ Permitted |
| **Source URL** | https://pub.dev/packages/file_picker |

### path_provider
| Field | Value |
|---|---|
| **Package** | `path_provider` |
| **Version** | `^2.0.0` |
| **Purpose** | Access to app-specific directories |
| **License** | **BSD 3-Clause** (Flutter team) |
| **Commercial distribution** | ✅ Permitted |

### freezed_annotation
| Field | Value |
|---|---|
| **Package** | `freezed_annotation` |
| **Version** | `^2.0.0` |
| **Purpose** | Annotations for immutable data classes |
| **License** | **MIT** |
| **Commercial distribution** | ✅ Permitted |

### json_annotation
| Field | Value |
|---|---|
| **Package** | `json_annotation` |
| **Version** | `^4.0.0` |
| **Purpose** | JSON serialization annotations |
| **License** | **BSD 3-Clause** (Dart team) |
| **Commercial distribution** | ✅ Permitted |

---

## Dev-Only Dependencies (not in release distribution)

| Package | Version | Purpose | License |
|---|---|---|---|
| `build_runner` | `^2.0.0` | Code generation runner | BSD 3-Clause |
| `freezed` | `^2.0.0` | Immutable class code generator | MIT |
| `json_serializable` | `^6.0.0` | JSON serialization generator | BSD 3-Clause |
| `riverpod_generator` | `^2.0.0` | Riverpod code generator | MIT |
| `flutter_test` | SDK | Test framework | BSD 3-Clause |
| `flutter_lints` | `^4.0.0` | Lint rules | BSD 3-Clause |

---

## Compliance Summary

| Requirement | Status |
|---|---|
| No paid APIs required | ✅ All packages are free/open-source |
| Commercial App Store/Play Store | ✅ All licenses permit commercial distribution |
| GPL/copyleft contamination | ✅ None — all MIT or BSD-3 |
| PDFium attribution in app credits | ⚠️ REQUIRED — "Copyright 2014 The PDFium Authors" |
| pdfrx attribution in source | ✅ Copyright notices must remain in source copies |

---

## Required App Credits Entry (Open Source Licenses screen)

Before Play Store / App Store submission, the following must appear in the app's Open Source Licenses screen:

```
PDFium
Copyright 2014 The PDFium Authors. All rights reserved.
License: BSD 3-Clause License
https://pdfium.googlesource.com/pdfium/

pdfrx / pdfrx_engine / pdfium_flutter
Copyright (c) 2018-2025 Takashi Kawasaki (@espresso3389)
License: MIT License
https://github.com/espresso3389/pdfrx
```
