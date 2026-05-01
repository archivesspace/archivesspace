# MCTF: Multilingual Content — Full Implementation Plan

## Context

The Multilingual Content Task Force (MCTF) project adds the ability to record, display, and
exchange archival descriptions in multiple languages. The JIRA tickets (MCTF-1 through MCTF-22)
were written when the scope was "multiple titles on a resource record." The actual implementation
(PR #3994, branch `ANW-2282-mlc-backwards-compatible`) and this design document expand that scope
to **all multilingual fields** across resources, archival objects, accessions, digital objects,
and digital object components. Every item below should be read with that broader scope in mind.

This document is based on the JIRA tickets on the [MCTF board](https://archivesspace.atlassian.net/jira/software/projects/MCTF/boards/56) and the latest understanding of the MLC requirements as in: [March 2026 MLC UI expectations doc](https://docs.google.com/document/d/1mO06XUBUkXaoItLwKe9Heia0GcrN75nPGM3PdWylyLU/edit?usp=sharing)

### Multilingual fields per record type (as declared in the backend models)

| Record type              | Multilingual fields                                                                                                                                                                                                          |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Resource                 | title, finding_aid_title, finding_aid_subtitle, finding_aid_author, finding_aid_sponsor, finding_aid_edition_statement, finding_aid_series_statement, finding_aid_note, repository_processing_note, finding_aid_filing_title |
| Archival Object          | title, display_string                                                                                                                                                                                                        |
| Accession                | title, content_description, condition_description, disposition, inventory, provenance, general_note, access_restrictions_note, use_restrictions_note, display_string                                                         |
| Digital Object           | title                                                                                                                                                                                                                        |
| Digital Object Component | title, label, display_string                                                                                                                                                                                                 |

### Key architectural decisions already made (PR #3994)[https://github.com/archivesspace/archivesspace/pull/3994]

- Each record type has a companion `_mlc` table with composite PK `(record_id, language_id, script_id)`.
- The `MultilingualContent` mixin overrides Sequel column accessors for every declared multilingual field, implementing transparent language-aware getters and setters. Reading `record.title` (or `record[:title]`) returns the value from the `_mlc` table for the current language context; writing `record.title = "..."` upserts the `_mlc` row for that language. Existing code that accesses these fields needs no modification.
- Language resolution order for mlc fields: `RequestContext.get(:language_of_description)` → primary `LanguageAndScriptOfDescription` row → `AppConfig[:mlc_default_language]` / `AppConfig[:mlc_default_script]` (defaults: `eng`/`Latn`)
   - `RequestContext.description_language` helper Returns a `{ language_id:, script_id: }` pair of `enumeration_value` IDs.
     - **First** — reads the thread-local context (`RequestContext.get(:language_of_description)`).
       The HTTP request layer populates this from the
       `X-ArchivesSpace-Description-Language` header (see the REST request-layer bullet below).
       Any wrapping `RequestContext.open(:language_of_description => …)` block further overrides
       it for the duration of the block.
     - **Otherwise** — resolves the deployment default by looking up
       `AppConfig[:mlc_default_language]` in the `language_iso639_2` enumeration and
       `AppConfig[:mlc_default_script]` in the `script_iso15924` enumeration, and caches the
       resolved pair back onto the active request context (so subsequent calls within the same
       request are free).
     - **The per-record primary-language step** listed in the Context resolution order above
       (primary `LanguageAndScriptOfDescription` row) is implemented on the `MultilingualContent`
       mixin as `primary_description_language` (memoised per instance) rather than inside
       `RequestContext.description_language`. The mixin's `get_field_value` / `set_field_value`
       currently call `RequestContext.description_language` directly; wiring the primary-row
       step between the thread-local check and the AppConfig fallback is a small follow-up
       (`get_field_value` → try `RequestContext` → try `primary_description_language` → try
       AppConfig defaults) so that records with an explicit primary language always resolve to
       that primary when no request-level override is in play, regardless of deployment defaults.
     - Returns `nil` only if the AppConfig defaults do not exist in the enumeration tables — an
       unreachable state in a correctly seeded database.
- A `language_and_script_of_description` subrecord (with `is_primary` flag) is wired to resources, accessions, and digital objects.
- The existing `languages` subrecord is renamed "Language of Materials" to distinguish it from the new "Languages of Description" subrecord.
- Data migration moves existing field values into the `_mlc` tables, defaulting to `eng`/`Latn`.

---

## 1. Backend — Core Data Model ✅ Done in PR #3994

- [x] `language_and_script_of_description` model, schema, and DB table
- [x] `_mlc` tables for all five record types, including `display_string` columns where relevant
  - migration 176
- [x] Data migration in 176 copies existing scalar field values into the `_mlc` tables under the
  configured `AppConfig[:mlc_default_language]` / `AppConfig[:mlc_default_script]`
  - the possibility to set a different default language and script before migrating the data needs to be documented as part of the upgrading procedure.
- [x] `MultilingualContent` mixin (`set_multilingual_fields` DSL, language-aware
  `get_field_value` / `set_field_value`, `[]` / `[]=` and `values` overrides so Sequel raw
  access and `NestedRecordResolver` see MLC-sourced values, `handle_delete` override to clear
  `_mlc` rows before parent deletion, buffered-write `@_mlc_pending` for unsaved records flushed
  in `after_save`) — methods documented with YARD tags
- [x] `LangDescriptions` mixin wired to **resource, accession, digital_object only**
  (archival_object and digital_object_component intentionally do not carry `lang_descriptions`;
  they inherit from their parent resource / digital_object)
- [x] `RequestContext.description_language` helper with resolution fallback chain
- [x] `RequestContext.resolve_language_pair(language_tag, script_tag)` helper — shared
  ISO-639-2/ISO-15924 → `enumeration_value` ID lookup, returns the `{ language_id:, script_id: }`
  pair or `nil`. Used by `description_language` (for the AppConfig-default branch) and by the
  REST request layer (see next bullet).
- [x] REST request-layer plumbing — `X-ArchivesSpace-Description-Language` header
  - `backend/app/main.rb#description_language_from_request` reads the header (format
    `"<iso639_2>_<iso15924>"`, e.g. `fre_Latn`), splits it, and resolves the pair via
    `RequestContext.resolve_language_pair`. Returns `nil` on absent / malformed / unknown
    values so downstream callers transparently fall through to the AppConfig default.
  - `backend/app/lib/rest.rb` — next to the existing `RequestContext.put(:repo_id, …)` and
    `:is_high_priority` writes, conditionally puts the resolved pair onto the request
    context as `:language_of_description`. The `if`-guard means requests without the
    header keep the existing behaviour (fall through to defaults in
    `RequestContext.description_language`).
  - Header-driven: matches the existing `X-ArchivesSpace-Priority` convention so the
    backend has one consistent way of accepting per-request metadata.
- [x] `AppConfig[:mlc_default_language]` / `AppConfig[:mlc_default_script]` config defaults
- [x] `lang_descriptions` property added to resource, accession, digital_object schemas
- [x] Large tree — `large_tree.rb`, `large_tree_digital_object.rb`, and the `Trees` mixin
  dispatch through a `display_strings` helper that picks `mlc_display_strings` (batch joins
  the `_mlc` table on the active `RequestContext.description_language`) for MLC-backed
  record types, and `non_mlc_display_strings` for legacy types
- [x] `ordered_records` updated to fetch `display_string` from the `_mlc` table
- [x] `spreadsheet_builder.rb` updated to fetch MLC title / display_string / label columns from
  the `_mlc` tables via a per-record-type `MLC_FIELDS_OF_INTEREST` map
- [x] Accession report and accession receipt report refactored to select titles from
  `accession_mlc` under a `lang_condition` built from `RequestContext.description_language`
- [x] Resource duplicate flow (`resource_duplicate_spec`, supporting code) updated for MLC
- [x] Test infrastructure: `find_by_mlc_title` spec helper in `backend/spec/mlc_spec_helper.rb`
  and factory_bot factory for `json_language_and_script_of_description`
- [x] `backend/spec/mixin_multilingual_content_spec.rb` covers the mixin

---

## 2. Staff UI — Language-of-Description Subrecord (MCTF-1)

Users must be able to record which languages a resource (or accession/digital object) is described
in, and which one is primary, before entering language-specific field content. See also the latest requirements document describing the Staff UI forms: [March 2026 MLC UI expectations doc](https://docs.google.com/document/d/1mO06XUBUkXaoItLwKe9Heia0GcrN75nPGM3PdWylyLU/edit?usp=sharing)

- [ ] Rename current "Languages" subrecord panel to "Languages of Materials".
- [ ] Display `lang_descriptions` subrecord panel similar to the "Languages of Materials panel", in resource / accession / digital object edit form
  - Title it as: "Languages of Description"
    - Subrecord fields:
      - language dropdown (ISO 639-2),
      - script dropdown (ISO 15924),
      - "Primary" checkbox
    - Only one entry may be marked primary (enforce client-side)
- [ ] Config flag `AppConfig[:multilingual_content]` gates all MLC UI; when disabled the subrecord panel is hidden and behaviour is identical to pre-MLC

---

## 3. Staff UI — Language Selector & Field Presentation (MCTF-1, [PR #4000](https://github.com/archivesspace/archivesspace/pull/4000) design)

Once a record has multiple languages of description, staff users must be able to switch which
language they are currently editing without leaving the record.

The changes outlined here are prototyped in [PR #4000](https://github.com/archivesspace/archivesspace/pull/4000).

### 3.1 Record toolbar — current-language selector

- [ ] Add "Descriptions" dropdown button to the resource record toolbar
  - `frontend/app/views/shared/_resource_toolbar.html.erb`
  - Lists all languages recorded in `lang_descriptions` using ISO 639-2 codes
    - Use the translations available in the current locale files for the language labels
  - Primary language entry carries a badge (reuse existing Bootstrap badge component)
  - Selecting a language sets a client-side state (JS) and triggers a form reload or in-place re-render for that language
    - Switching from one language to the other while having unsaved changes should give a warning
- [ ] Same toolbar addition for archival object, accession, digital object toolbars

### 3.2 Subform heading — current-language badge

- [ ] Render a small badge next to each subform heading that contains language-dependent fields
  - Shows the ISO 639-2 code of the currently-selected editing language
  - Only shown when MLC is enabled and the record has > 1 language of description
  - `frontend/app/helpers/aspace_form_helper.rb` — extend `subrecord_form_heading` helper

### 3.3 Language-dependent field labels

- [ ] Extend `aspace_form_helper.rb` `label_and_textarea` / `label_and_textfield` helpers
  - Detect when a field is language-dependent (check against a per-record-type list)
  - Append a small translate icon (Bootstrap `translate` SVG) to the label
  - Add a tooltip (Bootstrap `data-bs-toggle="tooltip"`) explaining the field is language-dependent
- [ ] CSS: `frontend/app/assets/stylesheets/archivesspace/form.scss` — style for the icon and the collapsible primary-value hint

### 3.4 Primary-language value reference (collapsed by default)

- [ ] Above each language-dependent field input, render a `<details>/<summary>` element
  - Shows the primary-language value for that field as a read-only reference
  - Uses native HTML (no JS required) for accessibility
  - Only rendered when the current editing language ≠ the primary language
  - `frontend/app/helpers/aspace_form_helper.rb` — new `primary_language_hint` helper

### 3.5 Form submission with language context

Backend note: the request-layer plumbing is already in place — `backend/app/lib/rest.rb`
reads the `X-ArchivesSpace-Description-Language` header and puts the resolved pair on
`RequestContext` before any endpoint body runs (see Section 1 above). The staff-UI work here
is purely about sending that header from the frontend Rails controllers when they proxy to
the backend.

- [ ] Frontend Rails controllers forward the currently-selected language as
  `X-ArchivesSpace-Description-Language: <iso639_2>_<iso15924>` on every request that creates
  or updates an MLC-backed record
  - `frontend/app/controllers/resources_controller.rb` (and equivalent for archival object,
    accession, digital object, digital object component controllers)
  - The selected language/script is already stashed in client-side state by the toolbar work
    in 3.1; the form submit handler passes it through to the Rails controller via a hidden
    field (`language_of_description[language]` + `language_of_description[script]`) which the
    controller reads and sets on the outgoing backend HTTP request's headers
  - Read operations (record fetch for the edit form) must send the same header so the backend
    returns the matching `_mlc` row in the scalar field values

---

## 4. Public UI — Display (MCTF-2)

Backend note: same plumbing as the staff UI — the backend resolves the active locale from
the `X-ArchivesSpace-Description-Language` header (see Section 1). PUI just needs to send it
on every backend request.

- [ ] PUI logic to resolve the user's preferred language:
  1. Show the value in the language matching the selected PUI interface language (`I18n.locale`), if a language of description exists for that language on the record
  2. Otherwise fall back to the primary language of description of the record (resource, accession, or digital object), or of the record's nearest ancestor that owns a `lang_descriptions` list (e.g. the parent resource for archival objects and digital object components)
- [ ] Send the resolved locale as `X-ArchivesSpace-Description-Language: <iso639_2>_<iso15924>`
  on every backend HTTP request so the API returns language-specific values in the scalar
  JSON fields. Central point: the PUI backend-client wrapper
  (`public/app/controllers/application_controller.rb` or the shared ArchivesSpaceClient) —
  one interception there covers every fetch path.
- [ ] Resource show view: render title from `display_string` (already language-specific if context is set)
  - `public/app/views/resources/show.html.erb`
- [ ] Archival object tree items: display_string is already batch-resolved via `large_tree.rb`

---

## 5. Search & Indexing (MCTF-12)

The indexer runs outside of a user request so there is no natural `RequestContext` language.
Strategy: index **all** language variants of each field simultaneously so every language is findable.

A key simplification: `fullrecord` / `fullrecord_published` are built by `build_fullrecord` →
`extract_string_values` recursively walking the record JSON, so simply including `mlc_fields` in
the serialised record makes every language variant full-text searchable through the existing
`fullrecord` mechanism — **no `copyField` gymnastics required**. The per-language dynamic-field
work is layered on top of that to enable fielded per-locale search with language-aware stemming
and stopwords for a curated shortlist of languages.

The work in this section is split across two PRs: the backwards-compatible base (PR #3994) laid
the `_mlc` table foundations, and [PR #4046 — `ANW-2282-mlc-index-with-mlc-fields`](https://github.com/archivesspace/archivesspace/pull/4046)
adds the indexing plumbing. The current-state sub-sections below cross-reference which PR
delivered each piece so it's clear what is in `master` vs. what is still stacked on top.

### 5.1 Backend serialisation — `mlc_fields` on the record JSON ✅ Done in PR #4046

The indexer receives its input as the regular record JSON produced by
`Model.sequel_to_jsonmodel`. Because there is no `RequestContext`, the MLC mixin's language-aware
scalar accessors fall through to the AppConfig default — any non-English primary-language record
would otherwise end up indexed with English scalars (or empty ones). PR #4046 fixes this by:
**(a)** attaching every language variant as `mlc_fields` on the outgoing JSON, and
**(b)** overwriting the scalar fields with the record's **primary** language value so display,
sort and facets stay correct regardless of what `RequestContext.description_language` happens
to resolve to.

- [x] `MultilingualContent::ClassMethods.to_mlc_hash(obj)` — returns every `_mlc` row keyed by
  `"<language_iso639_2>_<script_iso15924>"`, stripped of FK/enum ID columns so only translated
  field values remain. `backend/app/model/mixins/multilingual_content.rb`.
- [x] `MultilingualContent::ClassMethods.primary_description_language_for_record(obj)` —
  returns `{ language_id:, script_id: }` for the record's primary
  `LanguageAndScriptOfDescription`, or `nil`.
- [x] `MultilingualContent::ClassMethods.attach_mlc_fields_to_jsons!(objs, jsons)` — batched
  helper that:
  1. Issues one SELECT against the `_mlc` table for the whole batch, groups rows by record id.
  2. Issues one SELECT against `language_and_script_of_description` to find the primary
     language pair per record.
  3. Sets `json['mlc_fields'] = { "<lang>_<script>" => { <field> => <value>, … }, … }`.
  4. Overwrites each declared multilingual scalar (`title`, `display_string`, `label`,
     `finding_aid_*`, …) on the JSON with the primary-language value, independent of the
     thread-local request context.
- [x] Each MLC-using model invokes the helper at the bottom of its own `sequel_to_jsonmodel`:
  `backend/app/model/resource.rb`, `accession.rb`, `archival_object.rb`, `digital_object.rb`,
  `digital_object_component.rb`.
- [x] JSONModel schema additions so `mlc_fields` survives `to_hash(:trusted)`:
  readonly object property on `common/schemas/abstract_archival_object.rb` (covers resource,
  archival_object, digital_object, digital_object_component) and `common/schemas/accession.rb`.

### 5.2 Solr schema (`solr/schema.xml`) ✅ Done in PR #4046

Seven curated per-language analyzers plus a `text_general` catch-all, wired up as dynamic fields
with the naming convention `<field>_<iso_639_2>_mlc` (e.g. `title_eng_mlc`, `title_fre_mlc`,
`finding_aid_title_ger_mlc`). All dynamic fields are `indexed="true" stored="false"` — they
exist for querying, not display; scalar fields already carry the primary-language value for
display and sort.

- [x] Curated `<fieldType>` declarations using Solr's stock language analyzer stacks,
  all sharing `HTMLStripCharFilterFactory` + `LowerCaseFilterFactory`:
  - `text_eng` — `EnglishPossessiveFilter`, stopwords (`lang/stopwords_en.txt`),
    `PorterStemFilter`.
  - `text_spa` — stopwords (`lang/stopwords_es.txt`), `SpanishLightStemFilter`.
  - `text_fre` — `ElisionFilter` (`lang/contractions_fr.txt`), stopwords
    (`lang/stopwords_fr.txt`), `FrenchLightStemFilter`.
  - `text_jpn` — `JapaneseTokenizer`, `JapaneseBaseFormFilter`,
    `JapanesePartOfSpeechStopFilter` (`lang/stoptags_ja.txt`), `CJKWidthFilter`, stopwords
    (`lang/stopwords_ja.txt`), `JapaneseKatakanaStemFilter`.
  - `text_ger` — stopwords (`lang/stopwords_de.txt`), `GermanNormalizationFilter`,
    `GermanLightStemFilter`.
  - `text_ukr` — `ICUFoldingFilter` fallback (Solr's base distribution ships no Ukrainian
    stemmer; a real stemmer would require the MorphologikFilter + `uk` dictionary bundle,
    documented in the schema comment).
  - `text_dut` — stopwords (`lang/stopwords_nl.txt`),
    `StemmerOverrideFilter` (`lang/stemdict_nl.txt`), `SnowballPorterFilter language="Dutch"`.
- [x] Dynamic field declarations, specific matchers first so Solr picks them over the catch-all:
  ```xml
  <dynamicField name="*_eng_mlc" type="text_eng" indexed="true" stored="false" multiValued="false"/>
  <dynamicField name="*_spa_mlc" type="text_spa" .../>
  <dynamicField name="*_fre_mlc" type="text_fre" .../>
  <dynamicField name="*_jpn_mlc" type="text_jpn" .../>
  <dynamicField name="*_ger_mlc" type="text_ger" .../>
  <dynamicField name="*_ukr_mlc" type="text_ukr" .../>
  <dynamicField name="*_dut_mlc" type="text_dut" .../>
  <dynamicField name="*_mlc"     type="text_general" .../>
  ```
- [x] Stopwords / contraction / stemmer-override / stoptag files shipped in the PR under
  `solr/lang/` (separate commit `cd9003b9b`). File list:
  - `solr/lang/stopwords_en.txt`, `stopwords_es.txt`, `stopwords_fr.txt`, `stopwords_de.txt`,
    `stopwords_ja.txt`, `stopwords_nl.txt`
  - `solr/lang/contractions_fr.txt`, `stemdict_nl.txt`, `stoptags_ja.txt`
  - Ukrainian ships no extra file; ICU folding works purely on the filter factory.
- [x] `solr/Dockerfile` — `COPY *` → `COPY .` so the new `lang/` subdirectory is included in the
  Solr container build (the previous glob didn't recurse into subdirectories).
- [x] **No `copyField`** from `*_mlc` into `fullrecord`. The indexer walks `mlc_fields` via
  `extract_string_values` and routes every variant into `fullrecord` / `fullrecord_published`
  naturally, avoiding double-indexing and respecting the existing
  `IndexerCommonConfig.fullrecord_excludes` filter at every descent level.

### 5.3 Indexer (`indexer/app/lib/indexer_common.rb`) ✅ Done in PR #4046

The SUI/common indexer emits one dynamic field per `(language, field)` pair via a
`document_prepare_hook` added at the top of `configure_doc_rules`. Because PUI extends
`IndexerCommon`, the hook applies to PUI documents automatically.

- [x] `document_prepare_hook` reads `record['record']['mlc_fields']`, iterates every
  `lang_script => fields` entry, and writes `doc["#{field_name}_#{lang_code}_mlc"] = value`
  for each non-empty value, skipping anything listed in `IndexerCommonConfig.fullrecord_excludes`
  (notably `finding_aid_filing_title`, which already has its own dedicated sort field).
- [x] `fullrecord` / `fullrecord_published` population is untouched — the existing
  `extract_string_values` walker descends into `mlc_fields` on its own and inherits the root
  record's publish state, so MLC variants on published records flow into
  `fullrecord_published` and variants on unpublished records flow only into `fullrecord`.

### 5.4 Large-tree doc indexer — per-language cached trees ✅ Done in PR #4046

The tree-doc indexer precomputes four PUI doc types (`tree_root`, `tree_waypoint`, `tree_node`,
`tree_node_from_root`) by calling backend endpoints on `backend/app/model/large_tree.rb`. PR
#3994's MLC work made those endpoints language-aware via
`RequestContext.description_language`, but the indexer had no way to set that context — so every
cached tree previously rendered in `AppConfig[:mlc_default_language]`, regardless of the root
record's primary language.

Fix (split across backend + indexer):

- [x] **Backend — accept `description_language` query parameter.** All four
  `Resource`/`DigitalObject`/`Classification` tree endpoints take an optional
  `description_language=<iso639_2>_<iso15924>` param. `backend/app/controllers/resource.rb`,
  `digital_object.rb`, `classification.rb` add the param declaration and forward it into
  `LargeTree.new(…, :description_language => params[:description_language])`.
- [x] **Backend — `LargeTree` resolves and pins the language.**
  `backend/app/model/large_tree.rb`:
  - `resolve_description_language(lang_tag)` private helper parses
    `"<iso639_2>_<iso15924>"` via `BackendEnumSource.id_for_value`, falling back to the root
    record's primary `language_and_script_of_description` entry when the parameter is blank or
    unresolvable.
  - `with_description_language(&block)` wraps any `RequestContext`-sensitive code in
    `RequestContext.open(:language_of_description => @description_language, &block)` so the
    MLC accessors (`@root_record.title`, `node_record.display_string`, `mlc_display_strings`)
    all return values in the same pinned language.
  - All four entry points (`root`, `node`, `node_from_root`, `waypoint`) wrap their bodies in
    `with_description_language`.
- [x] **Indexer — index one cached tree-doc set per language of description.**
  `indexer/app/lib/large_tree_doc_indexer.rb`:
  - `fetch_language_tags(root_uri)` reads the root record's `lang_descriptions` array and
    returns every `"<lang>_<script>"` tag declared on it.
  - For records with no `lang_descriptions` (classifications, legacy data) a single
    unsuffixed doc set is indexed — PUI falls back to this when it can't find a
    locale-specific doc.
  - For records with `lang_descriptions`, one full doc set is indexed per tag. Solr `id`/`uri`
    on every doc is suffixed with the language tag, e.g. `#{root_uri}/tree/root/fre_Latn`,
    `#{root_uri}/tree/waypoint_#{parent_uri}_#{n}/fre_Latn`. The suffix is threaded through
    `add_waypoints` / `add_nodes` / `index_paths_to_root` via a `lang_tag` argument.
  - `pui_parent_id` stays language-agnostic so existing parent filters keep working.
  - `@deletes` accumulator is per-language too, cleaning up stale locale-specific node docs
    that no longer have published children.
- [x] `backend/spec/mixin_multilingual_content_spec.rb` extended with coverage for the new
  mixin helpers; `indexer/spec/indexer_common_spec.rb` adds a `mlc_fields indexing` describe
  block with four examples covering the dynamic-field emission, `fullrecord_excludes` filter,
  nil/empty-value skipping, and `fullrecord_published` routing.

### 5.5 What remains to be done

- [ ] **PUI — use the cached per-language tree docs.** The backend + indexer now emit
  locale-suffixed tree docs, but PUI tree fetches still hit the unsuffixed URI. The PUI
  Solr-read path (`public/app/models/…` tree fetch code) needs to build the lookup key from
  the user's active locale + the record's `lang_descriptions`, and fall back to the primary
  or to the unsuffixed doc when the user's locale has no matching entry. Tracked under §4
  (Public UI — Display) and touched by the PUI backend-client header wrapper in §4.
- [ ] **Search — per-locale query boosts.** Default search stays cross-language (via
  `fullrecord` / `fullrecord_published`), but the UI should layer locale-specific field
  boosts onto `qf` at query time. For example, when the PUI/SUI locale is French, append
  `title_fre_mlc^2` and `finding_aid_title_fre_mlc^1.5` to the existing `title_ws^2` `qf`.
  Implementation touches `backend/app/model/solr.rb` and `common/search_definitions.rb` — no
  schema or indexer change needed.
- [ ] **SUI — Advanced Search field picker.** If the Advanced Search UI is to expose
  fielded searches against a specific language's title (e.g. "search French titles only"),
  the field dropdown needs per-locale entries driven by the seven curated analyzers.
  Optional — can be deferred until there's user demand.
- [ ] **Operator documentation — which languages get stemming.** Release notes for the MLC
  rollout must list the seven curated analyzers (eng / spa / fre / jpn / ger / ukr / dut) so
  deployments know which ISO 639-2 codes benefit from language-specific stopwords and
  stemming, vs. the `text_general` catch-all used for everything else. Also flag the
  Ukrainian-stemmer limitation and the MorphologikFilter upgrade path.
- [ ] **Full reindex required on deploy.** The new dynamic fields and schema types mean every
  existing Solr core needs a full reindex after the upgrade (the indexer will repopulate
  every language variant automatically because `mlc_fields` is attached at record-JSON
  level — no data migration required, just index rebuild). Document in the release notes.
- [ ] **Integration test coverage** for the end-to-end multilingual search flow:
  1. Create a Resource with two `lang_descriptions` (e.g. `eng`/`Latn` primary,
     `fre`/`Latn` secondary) and distinct titles per language.
  2. Run the periodic indexer.
  3. Assert `q=<french title>` via `fullrecord` returns the record.
  4. Assert `qf=title_fre_mlc&q=<french title>` returns the record with a higher score than
     the fullrecord-only match.
  5. Assert the Solr doc's scalar `title` is the English (primary) value regardless of
     `RequestContext.description_language` at index time.
  6. Assert a tree fetch with `?description_language=fre_Latn` renders French titles, and
     the indexer produced a cached `…/tree/root/fre_Latn` doc for the same resource.
  Currently only unit-level specs exist for the mixin and indexer hook; the full pipeline
  is unverified.
- [ ] **Jobs and other non-request call paths.** See §17 (Background Jobs — Language of
  Description Propagation). The indexer fix in PR #4046 handles its own context via
  `LargeTree.with_description_language`, but other background jobs still need the queue-level
  language-pin work tracked in §17 before their output reflects the submitter's locale.

---

## 6. Exports

For all exporters the simplest approach is: the backend API already returns language-specific
values in standard fields when `RequestContext.description_language` is set. Exporters that call
the backend via the API automatically see the correct language value if the export request
includes a language parameter. Where an exporter needs to include **all** languages, extra work
is required.

### 6.1 EAD Export (MCTF-4)

- [ ] Expose language/script selection on the export form (or default to primary language)
- [ ] Set `RequestContext.description_language` before generating the EAD serializer
  - `backend/app/exporters/serializers/ead.rb`
- [ ] For multi-language EAD, output additional `<unittitle>` elements with `xml:lang` attribute
  per language variant (apply to resource and all archival object nodes)
- [ ] Apply same logic to other language-dependent resource fields (finding_aid_title, etc.) in the
  EAD `<filedesc>` section
- [ ] Update OAI-PMH responder to pass language context through to the EAD serializer

### 6.2 MARCXML Export (MCTF-5)

- [ ] Primary language maps to MARC field 245 (title statement)
- [ ] Additional language variants map to MARC field 880 (alternate graphic representation) with
  linking subfield `$6 245-...` and `xml:lang` on the datafield element
- [ ] Other multilingual resource fields (finding_aid fields) map to appropriate MARC fields with
  the same 880 pattern for additional languages
- [ ] `backend/app/exporters/serializers/marc21.rb`
- [ ] Update OAI-PMH MARCXML output

### 6.3 Dublin Core Export (MCTF-6)

- [ ] Output one `<dc:title xml:lang="...">` element per language variant
  - `backend/app/exporters/serializers/dc.rb` and `models/dc.rb`
- [ ] Same for any other DC elements that map to multilingual fields
- [ ] OAI-PMH DC output

### 6.4 DC Terms Export (MCTF-7)

- [ ] Output one `<dcterms:title xml:lang="...">` element per language variant
  - `backend/app/exporters/serializers/dcterms.rb`

### 6.5 MODS Export (MCTF-8)

- [ ] Output one `<titleInfo xml:lang="..."><title>` block per language variant
  - `backend/app/exporters/serializers/mods.rb` and `models/mods.rb`
- [ ] Other multilingual fields that map to MODS elements get the same treatment

### 6.6 PDF Export (MCTF-3)

- [ ] PDF generation goes through the public-facing API; pass language preference in the request
- [ ] `public/app/models/finding_aid_pdf.rb` — set language context before fetching records
- [ ] Title page and summary fields use `record.display_string` which is already language-specific
  if context is set
- [ ] Optionally render all language variants of the title on the PDF title page

---

## 7. Imports

For importers the key insight is: the `MultilingualContent` mixin's setter routes writes to the
`_mlc` table **if `RequestContext.description_language` is active**. So the strategy is to set
`RequestContext` before assigning field values during import.

### 7.1 EAD Import (MCTF-10)

- [ ] `backend/app/converters/ead_converter.rb`
- [ ] Read `xml:lang` attribute from `<unittitle>` elements
- [ ] For each `<unittitle>` with a distinct `xml:lang`, resolve language_id + script_id, set
  `RequestContext.description_language`, then assign `obj.title = ...`
- [ ] If `xml:lang` is absent, use the EAD-level `xml:lang` or default to `eng`/`Latn`
- [ ] Apply the same pattern to other language-dependent fields present in EAD
  (finding_aid_title maps to `<titleproper>`, etc.)
- [ ] First `<unittitle>` (or the one matching the primary language) sets the `lang_descriptions`
  entry with `is_primary: true`

### 7.2 MARCXML Import (MCTF-9)

- [ ] `backend/app/converters/marcxml_bib_converter.rb` and `lib/marcxml_bib_base_map.rb`
- [ ] Read primary language from MARC field 008 (positions 35-37) and set it as the
  `RequestContext.description_language` before assigning field 245 values
- [ ] Process MARC field 880 (alternate graphic representation) to import additional language
  variants — resolve language from the linking `$6` subfield or the `xml:lang` attribute
- [ ] Create `lang_descriptions` entries for each language discovered during import

### 7.3 JSON/API Import (MCTF-11) — partially done

- [ ] The backend JSON model for resource/accession/digital_object already includes `lang_descriptions`
  (added in PR #3994); verify that POST/PUT through the API correctly creates `_mlc` rows
- [ ] Extend the JSON schema to allow inline multilingual field values:
  `{ "title_mlc": { "eng_Latn": "...", "fre_Latn": "..." } }` as an optional supplement
  to the scalar `title` field (which continues to reflect the current-language value)
- [ ] Document the API contract for MLC-aware clients

---

## 8. CSV / XLSX Import Templates (MCTF-17 through MCTF-21)

All CSV/XLSX templates that include title (and other multilingual fields) need additional columns
for each language variant. The convention proposed: repeat the column with a language suffix,
e.g. `title`, `title__fre_Latn`, `title__spa_Latn`.

### 8.1 Accession import CSV (MCTF-17)

- [ ] `backend/app/converters/accession_converter.rb`
- [ ] Add columns: `title__<lang>_<script>` for each multilingual field
- [ ] Converter detects `__<lang>_<script>` suffix, sets RequestContext, assigns value

### 8.2 Bulk import AO CSV/XLSX (MCTF-18)

- [ ] `backend/app/lib/bulk_import/` — archival object import
- [ ] Same column-suffix convention; process additional language columns after primary

### 8.3 Bulk import DO CSV/XLSX (MCTF-19)

- [ ] Digital object bulk import — same pattern

### 8.4 Digital Object CSV import (MCTF-20)

- [ ] `backend/app/converters/digital_object_csv_converter.rb`
- [ ] Same pattern

### 8.5 Bulk edit export/import (MCTF-21)

- [ ] `backend/app/model/spreadsheet_builder.rb` — already partially updated in PR #3994
- [ ] Export: add language-suffixed columns for every MLC variant stored in `_mlc` tables
- [ ] Import: detect suffixed columns, route to correct `_mlc` row via RequestContext

---

## 9. Notes & Language/Script of Description (MCTF-13)

Notes are not stored in `_mlc` tables; instead, each note (or note content) can carry its own
`language` and `script` metadata so it is attributed to a specific language of description.

- [ ] Add `language` and `script` attributes to note schemas (single-part and multi-part)
  - `common/schemas/note.rb` (or equivalent per-type schema files)
- [ ] Display language/script selectors in the note subform UI
  - `frontend/app/views/shared/_subrecord_form_note_*.html.erb`
- [ ] PUI: display notes grouped or labelled by language
- [ ] Exports: EAD and MARCXML already support `xml:lang` on note elements — populate it from the note's `language` attribute

---

## 10. Sub-record Language/Script (MCTF-14)

Several sub-records within resource and archival object records (dates, extents, related agents,
etc.) may contain descriptive text that was authored in a specific language.

- [ ] Identify which sub-record types carry free-text description fields (e.g. `extent.container_summary`,
  `date.expression`, agent note sub-records)
- [ ] Add optional `language` + `script` fields to those schemas
- [ ] Display language/script selectors in the relevant sub-record form partials
- [ ] Exports: propagate language attributes to the corresponding XML elements

---

## 11. RTL (Right-to-Left) Support (MCTF-15)

- [ ] Detect when the current language of description is RTL (Arabic, Hebrew, Persian, Urdu, etc.)
- [ ] Apply `dir="rtl"` to language-dependent field inputs when an RTL language is active
  - `frontend/app/helpers/aspace_form_helper.rb`
- [ ] Apply `dir="rtl"` to PUI display elements that render RTL-language values
- [ ] CSS: `frontend/app/assets/stylesheets/archivesspace/form.scss` — RTL layout rules
- [ ] PUI stylesheet — RTL layout rules for record show pages

---

## 12. RDE (Rapid Data Entry) — Parking Lot (MCTF-16)

RDE currently has no support for repeatable fields of the same type. Until that architectural
limitation is addressed, MLC in RDE is deferred. No action planned at this time.

---

## 13. Light Mode (MCTF-22) — Parking Lot

Provide a simplified "light mode" that hides MLC complexity for single-language organisations:

- [ ] When `AppConfig[:multilingual_content]` is disabled (or when a record has exactly one
  `lang_descriptions` entry), show no language indicators, no toolbar selector, no
  primary-value hints — the UI looks identical to pre-MLC ArchivesSpace
- [ ] This is largely achieved by the config flag already planned in section 2; document the
  operator configuration steps

---

## 14. Configuration

- [ ] `common/config/config-defaults.rb`
  - `AppConfig[:multilingual_content]` — master on/off flag (default: `false`)
  - `AppConfig[:mlc_default_language]` — already added (`'eng'`)
  - `AppConfig[:mlc_default_script]` — already added (`'Latn'`)

---

## 15. Testing

- [ ] Backend unit specs for each new converter path (EAD import, MARCXML import language routing)
- [ ] `backend/spec/mixin_multilingual_content_spec.rb` — expand coverage for uncovered lines
  (noted in Coveralls report on PR #3994: 6 uncovered lines in the mixin)
- [ ] Exporter specs: assert that EAD/MARC/DC/MODS output includes correct `xml:lang` attributes
  for multi-language records
- [ ] Frontend Capybara/e2e specs:
  - Record with two languages: switch language in toolbar, verify field values change
  - Save record in non-primary language, reload, verify persistence
  - Primary-language hint shows correct value when editing in secondary language
- [ ] PUI specs: request with language param returns language-specific display_string

---

## 16. Documentation

- [ ] Operator guide: how to enable MLC via `AppConfig[:multilingual_content]`
- [ ] Staff user guide: "Languages of Description" workflow (add language → select current language → fill fields)
- [ ] API changelog: new `lang_descriptions` property, `mlc_fields` key, language query parameter

---

## 17. Background Jobs — Language of Description Propagation

### Context

The indexer is not the only code path that runs outside a user HTTP request. Every background
job (reports, bulk import, bulk archival-object update, find-and-replace, container conversion,
print-to-PDF, ARK generation, etc.) is dispatched by `BackgroundJobQueue` on a worker thread that
starts with no `RequestContext`. `RequestContext.description_language` therefore resolves to the
deployment default (`AppConfig[:mlc_default_language]` / `:mlc_default_script`) regardless of who
submitted the job or which language they were working in at the time. The concrete symptom today
is the accession receipt report (`reports/accessions/accession_receipt_report/…`) whose SQL
embeds the resolved `language_id` / `script_id` into its `lang_condition` — it always emits the
deployment default's `accession_mlc.title`, never the submitter's locale.

Several job runners already call `RequestContext.open(:repo_id => @job.repo_id, …)` inside
`#run` (`bulk_import_runner`, `bulk_archival_object_updater_runner`, `find_and_replace_runner`,
`ns2_remover_runner`, `container_labels_runner`, `generate_arks_runner`,
`resource_duplicate_runner`, `print_to_pdf_runner`, `top_container_linker_runner`,
`trim_whitespace_runner`, `batch_import_runner`), so they propagate the repository but not the
language. `reports_runner` does not wrap at all.

### Chosen approach: store the submitter's language on the `job` row

Capture `RequestContext.description_language` at job-submission time (inside the HTTP request
that creates the job) and persist the pair on the `job` row. When the worker thread picks the
job up, wrap the runner in `RequestContext.open(:language_of_description => …)` using the stored
pair. Jobs carry "the language I submitted this under" through the queue, across process
restarts and retries, and into every runner consistently.

With the Section 1 request-layer plumbing already in place, the submitter's language is
already resolved on the thread-local context when the job-creation endpoint runs — callers
that send the `X-ArchivesSpace-Description-Language` header get their chosen locale captured;
callers that don't send it get the AppConfig default captured. Either way, by the time
`Job.create_from_json` runs, a call to `RequestContext.description_language` returns the pair
to stamp onto the new columns.

Rejected alternative — derive from the owner user at run time: requires a new user-level language
preference (new column on `user` or new key in `preference`), loses snapshot semantics (if the
owner changes their preference between submission and execution, the queued job silently runs
under a different locale), and requires a `RequestContext` hook at request-start to populate
`:language_of_description` from the authenticated user's preference. Worth revisiting once a
per-user language setting is introduced elsewhere in the MCTF work.

### 17.1 Schema — new columns on the `job` table

- [ ] New migration (next available number after the MLC migrations) adds two nullable `Integer`
  columns to `job`:
  - `description_language_id` — FK to `enumeration_value.id`
  - `description_script_id`   — FK to `enumeration_value.id`
- [ ] Both nullable so that legacy rows (pre-migration queued jobs, jobs created via paths with
  no language context, scheduler-driven jobs) continue to work; the worker falls through to the
  existing `RequestContext.description_language` AppConfig fallback for null rows.

### 17.2 Job schema / model

- [ ] `common/schemas/job.rb` — add readonly string fields `description_language` and
  `description_script` so the API exposes the ISO codes for the jobs list UI and operator
  troubleshooting.
- [ ] `backend/app/model/job.rb`:
  - In `Job.create_from_json`, read `RequestContext.description_language` and pass the IDs into
    the `super` opts alongside `:owner_id` and `:job_type`.
  - In `Job.sequel_to_jsonmodel`, join `enumeration_value` on both columns and emit the
    resolved ISO codes onto the JSON.

### 17.3 Queue worker — wrap `runner.run`

- [ ] `backend/app/lib/background_job_queue.rb#run_pending_job`:
  - Before `runner.run` (line 128), read `job[:description_language_id]` /
    `job[:description_script_id]`.
  - If both are set, wrap the `runner.run` call in
    `RequestContext.open(:language_of_description => { language_id: …, script_id: … })`.
  - If either is nil, invoke `runner.run` directly — legacy behaviour preserved.

### 17.4 Job-runner hygiene

- [ ] No change needed inside runners that already call `RequestContext.open(...)` inside `#run`.
  Their `open` merges onto the outer context opened by `run_pending_job` (see
  `RequestContext.open` at `backend/app/lib/request_context.rb:15-29` — it preserves existing keys
  via the merge and restores the prior context on exit), so `:language_of_description` is
  inherited automatically.
- [ ] `reports_runner.rb` does not currently wrap in `RequestContext.open`; after the queue wrap
  is in place it inherits the language from the outer context. Verify with the accession
  receipt report, whose `lang_condition` reads
  `RequestContext.description_language` directly.

### 17.5 Tests

- [ ] `backend/spec/model_job_spec.rb` — submitting a job under a specific
  `RequestContext.description_language` persists the correct `description_language_id` /
  `description_script_id` on the row.
- [ ] New spec covering `BackgroundJobQueue#run_pending_job` — executes the runner with the
  persisted language pair active in `RequestContext`. Use a throwaway job runner that records
  `RequestContext.description_language` at run time and asserts on the pair.
- [ ] Integration spec: create an accession with two `lang_descriptions` entries and distinct
  titles per language. Submit the accession receipt report once per language. Verify each PDF
  contains the locale-appropriate title.

### 17.6 Edge cases to document

- **Retried (cancelled / failed) jobs** — keep their persisted pair; retries produce output
  consistent with the original submission.
- **Jobs enqueued by another job** — inherit the submitter's language via the parent job's
  `RequestContext` at the point of enqueue, so the child row is also stamped with the same pair.
- **Jobs enqueued programmatically** (scheduler, CLI, bootstrap) — no active `RequestContext`;
  persist `nil`/`nil` and run under the AppConfig default, same as today.

---

## File Reference (key files for implementation)

| Area | Files |
|---|---|
| Core mixin | `backend/app/model/mixins/multilingual_content.rb`, `lang_descriptions.rb` |
| Models | `backend/app/model/resource.rb`, `accession.rb`, `archival_object.rb`, `digital_object.rb`, `digital_object_component.rb` |
| Schemas | `common/schemas/resource.rb`, `accession.rb`, `digital_object.rb`, `language_and_script_of_description.rb` |
| Migrations | `common/db/migrations/176_create_lang_descriptions_and_mlc_tables.rb` (includes the merged `display_string` additions originally drafted as migration 177) |
| Config | `common/config/config-defaults.rb` |
| RequestContext | `backend/app/lib/request_context.rb` |
| REST request layer | `backend/app/lib/rest.rb`, `backend/app/main.rb` (header → `:language_of_description` plumbing) |
| Tree / display_string | `backend/app/model/large_tree.rb`, `large_tree_digital_object.rb`, `mixins/trees.rb` |
| Spreadsheet | `backend/app/model/spreadsheet_builder.rb` |
| EAD exporter | `backend/app/exporters/serializers/ead.rb`, `models/ead.rb` |
| MARCXML exporter | `backend/app/exporters/serializers/marc21.rb`, `models/marc21.rb` |
| DC exporter | `backend/app/exporters/serializers/dc.rb`, `models/dc.rb` |
| MODS exporter | `backend/app/exporters/serializers/mods.rb`, `models/mods.rb` |
| EAD importer | `backend/app/converters/ead_converter.rb` |
| MARCXML importer | `backend/app/converters/marcxml_bib_converter.rb`, `lib/marcxml_bib_base_map.rb` |
| Indexer | `indexer/app/lib/indexer_common.rb`, `pui_indexer.rb`, `large_tree_doc_indexer.rb` |
| Background jobs | `backend/app/lib/background_job_queue.rb`, `backend/app/lib/job_runner.rb`, `backend/app/model/job.rb`, `backend/app/controllers/job.rb`, `common/schemas/job.rb` |
| PUI controller | `public/app/controllers/application_controller.rb` |
| PUI views | `public/app/views/resources/show.html.erb`, `pdf/_resource.html.erb` |
| Frontend toolbar | `frontend/app/views/shared/_resource_toolbar.html.erb` |
| Frontend forms | `frontend/app/views/resources/_form_container.html.erb`, `frontend/app/helpers/aspace_form_helper.rb` |
| Frontend styles | `frontend/app/assets/stylesheets/archivesspace/form.scss` |
| Locales | `common/locales/en.yml` |
