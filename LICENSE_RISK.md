# Lexical Dataset Licensing & Risk Assessment

**Status:** DATA IMPORT BLOCKED (Awaiting Explicit Legal & Licensing Clearance)  
**Date:** September 2026  
**Scope:** Offline German Lexical Database (Wiktionary, Wiktextract, FreeDict, OdeNet, Tatoeba)

---

## 1. Candidate Data Sources & Exact Licenses

| Dataset Source | Upstream Origin | Exact License | Intended Use in App | Required Attribution Format |
| :--- | :--- | :--- | :--- | :--- |
| **Wiktextract (Kaikki.org)** | German & English Wiktionary | **CC BY-SA 4.0 / GFDL** | Core German offline dictionary, morphological headwords, IPA pronunciations, and multilingual sense glosses (EN, UR, FA, AR). | "Dictionary data from Wiktionary via Kaikki.org / Wiktextract contributors, licensed under CC BY-SA 4.0." Display in About Dialog & Lexicon Info screen. |
| **FreeDict (freedict.org)** | FreeDict Community | **GNU GPL v2+ / v3** | Secondary / fallback bilingual translations for German $\to$ English/Arabic/Farsi. | Prominent GPL copyright notice + offer to provide corresponding machine-readable dictionary dataset source. |
| **OdeNet (Open German WordNet)** | Hamburg University / OdeNet | **CC BY-SA 4.0** | Monolingual German synonym graphs and interlingual synset links. | Formal academic and project citation in application credits. |
| **OpenThesaurus** | Daniel Naber / OpenThesaurus | **GNU LGPL v2.1+** | German synonym lookup. | LGPL license notice + link to raw dataset source. |
| **Tatoeba Project** | Tatoeba community | **CC BY 2.0 FR** | Real bilingual example sentences illustrating word usage in context. | Attribution link to `tatoeba.org` and respective Tatoeba author IDs. |
| **GermaNet (Uni Tübingen)** | University of Tübingen | **GermaNet Academic License** | **EXCLUDED / REJECTED** | **NON-COMMERCIAL ONLY.** Strictly barred from commercial App Store / Play Store deployment. |

---

## 2. ShareAlike & Copyleft Implications (GPL / CC BY-SA)

### A. Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)
- **Derivative Database:** Modifying, extracting, or formatting the Wiktionary data into a compiled SQLite file creates an "Adapted Material" under Section 3(b). The resulting `.db` file must also be licensed under CC BY-SA 4.0.
- **Application Code Isolation:** The Flutter application source code, UI widgets, rendering pipelines, and proprietary algorithms are separate works communicating with the database file solely via standard SQL queries (mere aggregation). CC BY-SA 4.0 does *not* infect the application software itself.

### B. GNU General Public License (GPL v2+ / v3)
- If FreeDict raw data is converted and merged with Wiktextract data into the same database table, the FreeDict GPL clause could mandate licensing the entire merged database file under the GPL.
- **Engineering Recommendation:** Keep FreeDict tables or assets separated, or prioritize pure CC BY-SA sources (Wiktextract/Kaikki) to avoid GPL viral linkage ambiguity.

---

## 3. Unresolved Legal & Operational Questions

1. **App Store Terms vs. ShareAlike / GPL:**
   - Apple App Store Standard EULA contains DRM restrictions that some legal counsels argue conflict with pure GPL source-distribution requirements.
   - Using CC BY-SA 4.0 for the compiled SQLite asset while maintaining a separate commercial/MIT license for the Flutter binary is generally standard industry practice, but formal legal counsel review is advised before public release.
2. **Attribution Surface & Deep Linking:**
   - How granular must attribution be? Is a centralized in-app "Licenses & Acknowledgements" screen sufficient, or does every translation popup require a visible citation link?
   - Section 3(a)(1) of CC BY-SA allows attribution "in any reasonable manner based on the medium". A dedicated in-app modal and settings page meets standard criteria.
3. **Redistribution of SQLite Database:**
   - Does shipping a pre-compiled SQLite file count as "distributing" a derivative database that must be hosted on an open GitHub repository?
   - Yes, under ShareAlike, the transformed SQLite database file must be made accessible to users upon request under the same CC BY-SA 4.0 terms.

---

## 4. Engineering Policy & Current Enforcement

> [!IMPORTANT]
> **NO LEGAL CLEARANCE CLAIMED.**  
> Engineering can document licensing parameters, but production bulk import of the 700,000+ entry dataset remains **BLOCKED** until organizational legal counsel gives written clearance.  
> Currently, the application operates exclusively on a minimal, legally safe sample fixture (`kProductionSampleLexicon`) for end-to-end integration and automated verification.
