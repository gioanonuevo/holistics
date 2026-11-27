# Handover: `attention` dataset (Looker → Holistics migration)

Last updated: 2026-10-22. Owner: ganonuevo@verticalcity.com. Status tag: `Status/Draft`.

This note is the continuation point for future chats. Read it before touching
`datasets/attention.dataset.aml`, `models/attention_base.model.aml`,
`models/filter_model.model.aml` or `dashboards/looker_holistics_validation.page.aml`.

---

## 1. Environment (how to work on this project)

- **Edit in the WSL clone, never in the Windows folder.** Repo: `/home/giolisandro/holistics`
  (`\\wsl.localhost\Ubuntu\home\giolisandro\holistics` from Windows), branch `develop`.
  The background sync watches this clone and pushes every save to the Holistics cloud
  within seconds. The Windows folder `C:\Users\gldan\Desktop\Holistics` is NOT synced.
- **CLI:** `~/.holistics/bin/holistics` (not on PATH; auto-upgrades its core on first run).
  Auth: OAuth on `us`. Commands used all the time:
  - `holistics sync-code --background` (start), `--status`, `--status --wait` (block for a fresh cycle).
    The sync process dies when WSL restarts: always check `--status` first.
  - `holistics aml validate <files...>`
  - `holistics mcp <tool> '<json>'` (`execute_aql`, `fetch_dataset`, `search_docs`,
    `get_object_outline`, `read_data_source_table_schema`, ...). `execute_viz_block` ignores
    dashboard filters, so it cannot test a block that depends on a param.
- **Quoting trap:** `wsl.exe -d Ubuntu -- bash -lc '...'` strips double quotes inside the
  command, so `"$(cat x)"` and `"$f"` arrive broken. Put the command in a `.sh` file and run
  `bash /mnt/c/.../script.sh`, and keep JSON payloads in files. Never overwrite a repo file
  from a one-liner without checking its byte size first: an empty write syncs to the cloud
  instantly (this happened once; the cloud draft was lost and had to be rebuilt).
- **Edits from Windows tools** must be LF; strip CR with `sed -i 's/\r$//' <file>`.
- **Sync conflicts:** on restart the sync writes conflict markers into diverged local files and the
  marker-laden file can land on the cloud, where the object stops compiling (dataset "not found",
  dashboards full of "Expression is not evaluated to model"). Resolve by writing the clean content
  in place (`cat /tmp/x > file`; `sed -i` replaces the inode and the watcher misses it), then check
  the sync log shows `↑ pushed <file>` and `holistics mcp fetch_dataset` finds the dataset again.
  Keep exactly one sync process (`pgrep -af sync-code`).
- Test payloads used during this work live in the session scratchpad only; the pattern is
  `{"dataset_uname": "attention", "refresh_cache": true, "title": "...", "aql": "explore {...}"}`.

---

## 2. Architecture of the dataset

### Models
| Model | Role |
|---|---|
| `attention_base` (query) | Attention facts from `tech-data-warehouse.data_pipeline.attention_seconds_v3`, joined to `data_pipeline.properties` **on `property_number`** (Canada, `test = false`, `is_deleted = false`) and to `stg_campaigns` for `ads_type`. Has the `report_filter` param and clips itself to the selected flight window (see below). |
| `filter_model` (query) | Selection options: `report_filter` = campaign id (type Direct) or ad id (type Programmatic), one row per (report_filter, campaign_id, ad_id, type). Also `flight_start`, `flight_end`, `report_option` (= `id\|start\|end`, unused, kept as an option). |
| `data_pipeline_stg_campaigns` (table) | Bridge between `filter_model` and the scope/campaign paths (`ad_id`). Has several rows per ad (flights, reused ads). |
| `campaign_network_scope_bridge_v2` (query) | campaign/ad → (city, grouped ad length) from `creative_city_mapping`. |
| `network_scope_v2` (query) | Unique (city, grouped ad length) keys; `network_scope_key = city\|\|ad_length_grouped`. |

### Relationships (one path only: Holistics propagates a filter through a single path)
```
attention_base.network_scope_key > network_scope_v2.network_scope_key   (active, one_way)
attention_base.ad_id             > data_pipeline_stg_campaigns.ad_id     (INACTIVE, two_way)  <- campaign path, activated per metric
campaign_network_scope_bridge_v2.network_scope_key > network_scope_v2.network_scope_key (active, two_way)
campaign_network_scope_bridge_v2.ad_id > data_pipeline_stg_campaigns.ad_id (active, two_way)
data_pipeline_stg_campaigns.ad_id > filter_model.ad_id (active, two_way)
```
A filter on `filter_model.report_filter` flows: filter_model → stg_campaigns → bridge_v2 →
network_scope_v2 → attention_base. That is the **network scope** (same cities and ad lengths
as the selected campaign, all campaigns). Metrics that need the campaign's own events use
`with_relationships(attention_base.ad_id > data_pipeline_stg_campaigns.ad_id)`.

### Flight-date clipping (why there is a param)
- Holistics evaluates dataset dimensions before explore filters, so a dimension that embeds
  `min/max(flight dates)` always sees the unfiltered window. And a second relationship chain
  for dates is ignored (single-path rule). So the date clip lives **inside `attention_base`'s SQL**:
  param `report_filter` → `{% filter(report_filter) %} report_filter {% end %}` over the same
  union as `filter_model` → min/max flight window → `GENERATE_DATE_ARRAY` → `INNER JOIN ... ON
  DATE(attention.start_at_utc) = dates`. Columns produced: `is_in_flight_range` (true for every
  surviving row), `selected_flight_start_date`, `selected_flight_end_date`.
- With no param value the placeholder renders `1 = 1`: window = every flight date ever.
- **Dashboard wiring (one control):** FilterBlock sourced from `r(attention_base.report_filter)`
  (param-sourced; a dimension-sourced filter does NOT feed a param, and a param-sourced filter
  does NOT feed a dimension), interaction to that param, plus a viz-level AQL condition:
  ```
  conditions: ["filter_model.report_filter == coalesce((attention_base.report_filter | first()), '__all__') or coalesce((attention_base.report_filter | first()), '__all__') == '__all__'"]
  ```
  The coalesce sentinel is required: an empty param renders `= NULL`, which BigQuery rejects
  (`Operands of = cannot be literal NULL`); `is null` guards still emit it; coalescing to another
  column crashes the AQL compiler. Empty control ⇒ all data (35.8M events, avg 5.142).
- Params have no model-level default (`Param` only has label/type/hidden/description/allowed_values).

### BigQuery partition pruning (resolved 2026-11-16: v3 now prunes)
`attention_seconds_v2` and `_v3` have identical DDL (PARTITION BY DATE(start_at_utc), CLUSTER BY
campaign_id, ad_id). In October the date-equality inner join pruned v2 (184.8 MB vs 1.75 GB) but
NOT v3, and not a quarter-size copy of v2 either: BigQuery's join pruning is size-gated (somewhere
between ~46M and ~185M rows), and v3 was below the gate. A literal-param design
(`filter_model.report_option` as `id|start|end` injected with `{{ report_option }}`) was built,
proven to prune, and then removed in favour of the join (kept only as the `report_option`
column). Test SQL: `notes/pruning_test_variants*.sql` in the Windows folder.

Re-test 2026-11-16 (campaign 10605, window Aug 12 - Oct 1 2026, executed jobs, bytes processed):
the v3 date-equality join (the exact shape `attention_base` generates) and the v3 literal
timestamp filter both read ~1 GB, while the v3 full scan read 18.5 GB. So the join now prunes v3
and `attention_base` as written is partition-pruned; no literal-param clip is needed. The full
scan is far larger than October's 996 MB, so v3 itself grew a lot (consistent with crossing the
size gate). Re-run queries 1, 3 and 4 above if the table is rebuilt or shrinks.

---

## 3. Metrics (all in `datasets/attention.dataset.aml`)

| Metric | Definition (AQL) | Notes |
|---|---|---|
| `base_average_attention_seconds` | `avg(attention_base.attention_seconds)` with ad_id/attention not null | Follows table grouping. |
| `attention_seconds_average` | base \| `with_relationships(attention_base.ad_id > stg_campaigns.ad_id)` | Row-level attention of the selection's own events (per ad / city / demo). The "attention" side of every comparison. |
| `campaign_average_attention_seconds` | `attention_seconds_average \| of_all(attention_base, keep_filters: true)` | ONE number for the whole selection (a campaign, or several ad ids that make up one campaign), same on every row of a breakdown. Matches Looker to 9 decimals at campaign level. Changed 2026-10-20 at the user's request: it used to follow the table grouping. |
| `average_attention_seconds` | base \| `of_all(filter_model.report_filter, keep_filters: true)` | **Network** average; keeps every other grain of the table (so grouped by gender it is per gender, grouped by ad it is per ad!). |
| `attention_events` | count of network events, same scope as above | |
| `selected_campaign_start_date` / `_end_date` | `max(attention_base.selected_flight_*)` | |
| `campaign_datapoints` | `count(attention_base.uuid)` on the campaign path | "Datapoints". Plain row count by the user's decision (2026-10-20): v3 rows are taken as they are (10605: 32,156 rows, 29,662 distinct uuids), like Looker's `attention_seconds_count`. Beware the stg_campaigns fan-out on this path (see open items). |
| `network_average_overall` | network avg \| `of_all(attention_base, keep_filters: true)` | One number, Looker `attention_network_average`. |
| `attention_vs_campaign` | `safe_divide(attention_seconds_average − campaign_average, campaign_average)` | 0% at campaign level; per creative/city/demo rows. Format `0.0%`. |
| `attention_vs_network` | `safe_divide(attention_seconds_average − network_average_overall, network_average_overall)` | Looker definition (not ad-length weighted). Format `0.0%`. |
| `network_average_by_gender` / `_by_age_group` / `_by_gender_age` | network avg \| `keep_grains(attention_base.gender[, attention_base.age_group], keep_filters: true)` | Looker `attention_network_gender/age/demo_average`. Only meaningful in tables grouped by that demographic. |
| `attention_vs_network_by_gender` / `_by_age_group` / `_by_gender_age` | `safe_divide(attention_seconds_average − network_by_x, network_by_x)` | Same grouping rule. |

Semantics agreed with the user (2026-10-19): vs Campaign denominator = whole selected campaign;
vs Network = Looker's plain network average; demographic variants only used when the table is
grouped by that demographic; ratios with percent format.

### Future option: ad-length-weighted network benchmark
The client dashboard uses `Σ(share of campaign datapoints per ad length × network average per ad
length)`. Doable in AQL: `network_by_length = average_attention_seconds | keep_grains(attention_base.ad_length_grouped, keep_filters: true)`,
`share = campaign_datapoints / (campaign_datapoints | of_all(attention_base.ad_length_grouped, keep_filters: true))`,
then a dimensionalized sum over ad length (`sum(... | dimensionalize(attention_base.ad_length_grouped))`).
Not built; verify the nested-aggregation syntax with `search_docs` first.

---

## 4. Validation baseline (campaign 10605, Direct, window Aug 12 – Oct 1 2026)

| Metric | Holistics | Looker |
|---|---|---|
| Campaign average | 5.199657363 | 5.199657363 |
| Network average | 5.233176654 | 5.233521208 |
| Network events | 85,040 (Calgary only, 15s only) | n/a |
| Datapoints | 32,156 rows (29,662 distinct uuids) | 32,156 COUNT(*) |

The network gap is explained: Looker inner-joins `detection_demography_v2`, which has ~726k
duplicate uuids (274,338,005 rows vs 273,612,013 distinct), double-weighting those events.
Deduplicating that CTE in the Looker SQL reproduces the Holistics number.

Programmatic check (ad 101617): window Aug 12 – Sep 8, 2,960 events, network 5.62 vs campaign 5.10.

Multi-ad Programmatic check (2026-10-20, dashboard tab 2): ads 69d6b7f1dd289cab8bbe075a,
69d6b809dd289cab8bbe075f, 6a03890a61b5f9ea1e4f40a6, 6a03890a61b5f9ea1e4f40a7, 6a03890a61b5f9ea1e4f40a8,
6a03890a61b5f9ea1e4f40a9 selected together (multi-value control, block condition
`filter_model.report_filter in attention_base.report_filter`): 30,356 datapoints, campaign avg 5.564,
network avg 5.384 over 2,111,623 network events, vs network +3.3%, envelope window Apr 13 – Jun 30 2026.
**Bug found and fixed on the way:** Programmatic rows have a NULL campaign_id in both `stg_campaigns`
and `creative_city_mapping`, and `campaigns.campaign_id = mapping.campaign_id` never matches NULL to
NULL, so the v2 bridge produced no scope for them (network = 0 events). Both
`campaign_network_scope_bridge_v2` and `network_scope_v2` now join on
`coalesce(cast(campaign_id as string), '')`; the bridge primary key also became null-safe
(`coalesce(campaign_id,'') || ad_id || scope_key`). `selected_campaign_start/end_date` now read through
the campaign path (`with_relationships`) so they are not blank when the network scope is empty.

**Programmatic network gap explained (2026-10-21):** Holistics 5.383776 vs Looker 5.361545 (Looker run
with DISTINCT demography). Cause: scope semantics. Looker scopes the network by **observed cities**
(where the selected ads actually played, screen MAC -> property) **crossed with all selected ad lengths**
(two independent INNER JOINs), while the v2 bridge scopes by **mapped cities paired with each creative's
own length** (`city||ad_length_grouped` keys). With 15s ads in some cities and 10s ads in others the
sets differ (Looker adds e.g. Calgary / Edmonton / Ottawa 10s cells and drops Sherwood Park and
Surrey 10s). Reproducing Looker's semantics in Holistics (observed cities x {10,15} inside the six-ad
window, no scope chain) gives 5.361212 over 2,221,534 events; the remaining 0.0003 is the demography
residue. For a single-city, single-length Direct campaign (10605) both semantics coincide.
Decision pending with the user: keep the pair semantics (campaign-specific) or match Looker. Matching
Looker would mean computing scope flags inside `attention_base` from the `report_filter` param (SQL
subqueries for the selection's cities and lengths), because a second relationship chain cannot be
used (single-path rule); that would also remove the need for the viz condition.

**Direct multi-campaign gap explained (2026-11-20, campaigns 10617 + 10618 + 10619, all 15s):**
Holistics network 5.258771 over 685,143 events (Calgary, Edmonton, Toronto, Vancouver x 15s, window
Sep 1 - Oct 26 2026; flights are contiguous so the min/max window equals Looker's date union). Mapped
cities = observed cities here, so scope semantics are identical. The difference is **how Looker finds
the observed cities**: its `city_clipping_helper` resolves the city through `device_id ->
screen_mac_address_lookup_v2 -> views_properties_query_results` (status 'ready'), not through the
event's `property_id`. 108 of the campaigns' 60,668 events sit on screens whose lookup property is in
**North York** while the event's property_id says Toronto, so Looker adds the whole North York cell
(197,942 events, avg 5.35) to the benchmark: 883,085 events, avg 5.27838 (reproduced in a temporary
model with Looker's helper SQL, including the demography inner join; deleted afterwards). Holistics is
the self-consistent one (the same property drives the event's city and the network's city). The 108
events all come from one screen, MAC `c0-fb-f9-c6-61-93`, Sep 1-6 2026, campaign 10617: the events
carry property 756 (Corktown District II, Toronto) while `screen_mac_address_lookup_v2` maps the MAC to
property 161 (Chicago Residences, North York), a single lookup row, i.e. a stale or re-deployed screen
record. If Looker
parity is ever required, the fix is a scope flag for the screen-lookup cities, not a metric change.
Looker also unions each flight's own dates (gaps between non-contiguous flights excluded) whereas the
param clip uses min/max of the selection; irrelevant for contiguous flights.

### Validation dashboard
`dashboards/looker_holistics_validation.page.aml` is a two-tab `TabLayout`:
- **Direct 10605**: intro text explaining the mechanics, multi-value control `f_report`
  (param-sourced, default 10605; made multi-value on 2026-11-20, campaign ids and ad ids can be
  mixed), tables: campaign level, by ad, by gender, by gender x age. Its condition is
  `coalesce((attention_base.report_filter | first()), '__all__') == '__all__' or
  filter_model.report_filter in attention_base.report_filter` (empty control = all data; validated
  by the CLI, the empty-control case is not yet exercised in Studio).
- **Programmatic ads**: multi-value control `f_ads` (default = the six ids above) wired only to the
  tab-2 blocks, which use the same condition as tab 1 since 2026-11-24 (empty control = all data;
  before that the bare `in` returned 0 rows when the control was cleared).
Each control is a separate FilterBlock on the same param; `explicit_interactions` maps each to its own
tab's blocks only. Multi-select + `first()` would only use the first value, hence `in`. With several
campaigns selected everything is pooled: one min/max window, one network (union of the selection's
city x length cells), one campaign average. Campaigns never share creatives (user, 2026-11-20), so
the stg_campaigns fan-out does not bite.

Two bugs fixed on the way, both worth remembering:
1. `attention_base` joined `properties.id`; the attention tables carry the property **number**
   (`properties.property_number`). Wrong key ⇒ random city/province ⇒ network avg 5.54.
2. The original dataset dimension `is_in_flight_range` compared against unfiltered min/max bounds
   (true for everything).

---

## 5. Known issues / open items

- **v3 duplicate uuids** (8% for 10605). Averages include them (as Looker does). Decide whether
  the pipeline that builds `attention_seconds_v3` should dedupe; if so, re-validate everything.
- **stg_campaigns fan-out on the campaign path**: `campaign_average_attention_seconds` is an
  average over joined rows; an ad with several stg rows weighs more. It matched Looker for 10605,
  but check a campaign with reused ads. A fix would be an inactive relationship to
  `filter_model.ad_id` instead (one row per ad under a report filter).
- Dashboards that referenced the old helper models in this dataset are now broken:
  `dashboards/looker_partition_mimic_poc.page.aml`, `dashboards/test.page.aml`
  (they reference `flight_date_range_clipping_helper_v` / `data_pipeline_creative_city_mapping`
  via dataset `attention`). Either repoint them or delete them.
- `datasets/attention_backup.dataset.aml` (`Dataset attention_copy`) was created by the user in
  the cloud on 2026-10-19 as a backup; keep it in sync or delete when done.
- `holistics aml validate` on a dashboard crashed the CLI (`r.data.find`) when the dashboard
  referenced a dataset-qualified field that had become a model field; the fix is the ref form,
  not the CLI.
- CLI core now 2.4.2; CLAUDE.md still says 2.3.24.

## 6. Suggested next steps
1. More metrics from the client dashboard dictionary: Active Attention % (share of
   `exposure_category = 'Message Exposure'`), exposure tiers, trend series (daily/weekly with the
   ≥99-observation rule), per-city / per-property / per-creative segment tables.
2. Dashboard: replace the validation table with the real client layout; one param-sourced
   control + the coalesce condition on every block of dataset `attention`.
3. Decide on duplicates and on the ad-length-weighted benchmark.

---

## 7. V+ report extract (draft, 2026-10-21, awaiting user review)

Purpose: single wide source for the automated V+ post-report deck (see Windows `notes/vplus_deck_data_layer.md`).

Files changed in this clone (synced to the cloud draft, validated with `aml validate`, not yet reviewed):
- `models/attention_base.model.aml`: new columns + dimensions `province` (properties.region_short), `fsa`
  (SUBSTR(postal_code,1,3)), `property_type` (COALESCE(iab_lookup_canada.string_field_1, properties.property_type_text),
  new LEFT JOIN on `iab.string_field_0 = properties.property_type`), `property_type_broad` (Residential when Condo /
  Luxury Rental else Commercial, same rule as Client Dashboard v2 `property_type_2`). Additive only.
- `datasets/attention.dataset.aml`: new metric `campaign_attention_seconds_sum` (sum on the campaign path, same
  `where` as `campaign_datapoints`). sum / datapoints = `campaign_average_attention_seconds` at any grain.
- `dashboards/vplus_report_extract.page.aml`: one multi-value control on the param (default 10605), block condition
  `filter_model.report_filter in attention_base.report_filter`, `v_totals` (reconciliation row) and `v_report`
  (day x ad x ads_type x ad_length x city x province x fsa x property types x gender x age x exposure, with datapoints,
  sum, campaign avg, network avg, network by gender / age / gender x age; row_limit 500000).

Checks on 10605 (execute_aql, refresh_cache): property summary AB only, Commercial 81 / Condo 8,255 / Luxury Rental
23,820 datapoints (= 32,156), 5 FSAs; full report 13,834 rows; campaign avg 5.199657, network 5.233177 unchanged.

AQL gotchas learned: explore dimensions must be labelled (`city: attention_base.city`), the param goes in a
`params { attention_base.report_filter in ['10605'] }` block, filters use `is` / `in`. `generate_aql` emits the right form.

Open for review: (1) `property_type` falls back to `properties.property_type_text` when the IAB lookup has no match
(Looker/v2 would give NULL); (2) null granular type maps to Commercial, as in v2; (3) `execute_viz_block` ignores
dashboard params, so the page was validated but its blocks were not executed from the CLI; open it in the UI.
Next: second dataset for creatives (names, CG1/CG2), flights (booked impressions, contract value), served impressions,
screen count; then the Python extractor against the widget export API (needs an API key).

**2026-10-22 revert:** at the user's request the four property columns were removed from `attention_base` again (file
restored byte-for-byte to the pre-edit version, 11,870 bytes). The user will create a separate property model for
province / FSA / property type. `vplus_report_extract.page.aml` no longer lists those four fields; the
`campaign_attention_seconds_sum` metric stays. The derivation SQL that worked is kept in section 7 above for reuse.

## 8. Property / screen / creative models joined to attention_base (2026-10-22)

User added `properties` (query model over data_pipeline.properties + iab_lookup_canada, id = property_number, FSA,
address_province short code, granular property_type), `screens` (mac_address with '-' separators, property_id =
property_number, screen_location Lobby/Elevator) and `creative_img` (ad thumbnails), related as
`attention_base.device_id > screens.mac_address`, `screens.property_id > properties.id`, `attention_base.ad_id > creative_img.ads_id`.

Join audit and fixes (all verified on 10605 after the change):
- `creative_img.ads_id` was BIGNUMERIC vs text `attention_base.ad_id` -> BigQuery "No matching signature for operator =".
  Now `cast(... as string)`, dimension type text. It also had 121 duplicate ad ids (21,885 rows / 21,764 distinct) ->
  `QUALIFY ROW_NUMBER() OVER (PARTITION BY ads_id ORDER BY src, creative_img) = 1` (raw_ads branch wins). Now 21,764 / 21,764.
- `screens.mac_address` was not unique (16,620 rows / 15,210 MACs; null MACs included) -> `where mac_address is not null`
  + `qualify row_number() over (partition by mac order by last_seen_at desc, id desc) = 1`. Now 15,210 / 15,210.
  10605 was unaffected either way (Elevator 32,075 + Lobby 81 = 32,156, 21 devices all matched).
- `properties` is unique on id (1,612). Added dimension `property_type_broad` (Residential for Condo / Luxury Rental, else Commercial).
- Dataset: new metric `campaign_screens` = count_distinct(attention_base.device_id) on the campaign path (10605: 21).
- Report page `vplus_report_extract`: v_report now carries properties.address_province, fsa, property_type_broad,
  property_type, screens.screen_location, creative_img.media_type, creative_img.creative_img; v_totals carries campaign_screens.
  10605: 13,834 rows, 32,156 datapoints, 167,200.18 s.

Design caveat (not changed): property attributes reach attention_base only through screens (device_id -> MAC -> property).
A device missing from `screens` loses its province / FSA / property type even though attention_base has property_id.

**2026-11-25: `creative_groups_lu`** (query model over `data_pipeline.stg_client_dashboard_creative_groups_lu`,
`creative_id` cast to text and deduplicated with `QUALIFY ROW_NUMBER()`, dims `creative_group`, `creative_group2`),
related `attention_base.ad_id > creative_groups_lu.creative_id` (active, leaf model like `creative_img`). It carries
the client-dashboard creative grouping into the deck pipeline's report extract (`creative_grouping` toggle). Coverage
checked: all 15 ads of 10605 and the 4 of The Gathering have a `creative_group` (e.g. 101691 = "72 Hours",
101692-4 = "Join Us"); `creative_group2` is null for them. Validated and synced to development; **production needs a
publish before the pipeline's `extract --force` can see the field.** A cloud-made table model
`data_pipeline_stg_client_dashboard_creative_groups_lu` (raw table, no dedup) also exists and is not in any dataset.

Same day, `creative_img` gained `ad_name`: `raw_ads.title` on the raw-id branch, `elev8_ads_ads.name` on the
ad_number branch (the one the attention ad ids hit; raw_ads.id never matches a 1016xx ad, which is why the first
attempt returned null everywhere). For 10605 the names are internal codes ("1000062661 RES 5am - 11:59pm"); the deck
pipeline uses them only when no config name or group exists.
A direct `attention_base.property_id > properties.id` relationship would be more robust, but it would create a second
path to properties, so the screens -> properties relationship would then have to become inactive. Decide with the user.

**Decision 2026-10-22:** keep property attributes routed through screens (no direct attention_base -> properties relationship).

## 9. Delivery dataset `vplus_delivery` (2026-10-22): flights + served impressions

Separate dataset so the attention dataset's single-path design stays untouched. Models:
- `vplus_flight_facts` (query): one row per attention-side campaign id. **Id spaces differ:** `elev8_ads_flights.campaign_id`
  is the elev8 internal id (237, 273, ...), `campaign_reporting_campaigns.campaign_number` has no 10605, and the attention
  campaign id 10605 corresponds to elev8 **flight** 605 (ads 101617.. have `elev8_ads_ads.flight_id = 605`, `ad_number = 101617`).
  So the model maps flights -> ads (`elev8_ads_ads.flight_id`, `ad_number`) -> `stg_campaigns.ad_id` -> `campaign_id`, then sums
  booked_impressions, contract_value_in_cents/100, make_good_credit_in_cents/100 and takes min start / max end, flight_ids, ad_lengths.
- `vplus_served_impressions` (query): plays_summary at campaign x ad x date, inner-joined to the (campaign_id, ad_id) window
  from stg_campaigns (min start_at / max end_at), same source as attention_base's clip. Programmatic: filter on ad_id.
- `data_pipeline_campaign_reporting_campaigns`, `data_pipeline_elev8_ads_ads`: included, no relationships (ad names, lookups).
- Relationship: `vplus_served_impressions.campaign_id > vplus_flight_facts.campaign_id` (two_way).
- Metrics: booked_impressions, served_impressions, bonus_impressions (= served - booked, user's definition), contract_value,
  make_good_credit, cpm (= contract / booked x 1000, assumption to confirm vs Looker flights_summary), flight_start, flight_end.

10605: flight 605, 15 s, CAD, flight window Aug 12 - Sep 30 2026, booked 3,316,875, served 3,649,599 (18 ads, per-ad
windows Aug 12 / Aug 25 / Sep 4 -> Sep 8), bonus 332,724, contract 26,535.00, make-good 0, CPM 8.00.
Sanity: 10604 -> flight 604 (3,297,500 booked), 10368 -> flight 368 (2,301,153).

**Open:** three different windows exist for 10605: flight (Aug 12 - Sep 30), stg_campaigns ad windows (end Sep 8), and the
attention clip `selected_campaign_end_date` (Oct 1). The deck's start/end slide should state which one it shows.
Looker's Look 40 also had rate card value and bonus value; neither is in elev8_ads_flights. Ad names in `elev8_ads_ads.name`
are often internal codes (e.g. 1000062661); the deck's creative names came from Looker's creatives / creative group lookup.

Report page `vplus_report_extract` now has controls `f_delivery` (campaign id, default 10605) and `f_delivery_ads`
(ad ids), blocks `v_delivery` (campaign facts) and `v_served_by_ad`. Validated and synced; blocks not executed from the CLI.

**Correction to section 9 (2026-10-22, later):** `vplus_flight_facts` no longer uses elev8_ads_flights or the ads mapping.
Looker's `flights` view is `select * from data_pipeline.raw_campaigns`, and `raw_campaigns.id` IS the attention campaign id
(10605), so the model reads raw_campaigns directly, one row per flight, with the Looker `flights_summary` logic:
contract_cost = standard_price_cents/100; rate by ad_duration (5 s 700, 10 s 900, 15 s 1050, 30 s 1325, else 800 cents per
1000); booked_value (rate card value) = actual_value_cents when present else rate x max(booked, actual)/1000, /100.
Dataset metrics: booked_impressions, flight_actual_impressions (raw_campaigns.actual_impressions), served_impressions
(plays_summary), bonus_impressions = served - booked, total_contract_cost, rate_card_value, bonus_value =
case(when rate_card_value > total_contract_cost ...) (no `greatest` in AQL), cpm = coalesce(safe_divide(cost, booked)*1000, 0),
flight_start/end, flight_count. `data_pipeline_raw_campaigns` added to the dataset.
10605: 1 flight, Aug 12 - Sep 30, booked 3,316,875, flight actual 3,649,599 (= served from plays_summary, exact), bonus
332,724, cost 26,535.00, rate card 38,320.79, bonus value 11,785.79, CPM 8.00. 3907 (notebook example): cost 6,600.67,
rate card 12,212.58. Programmatic ad: CPM 0, bonus value 0.
Report page: `v_delivery` (summary metrics), `v_flights` (raw_campaigns rows), `v_served_by_ad`.
The Looker project export used for these definitions: `C:\Users\gldan\Downloads\looker-main-master\looker-main-master\views\flights_summary.view.lkml`.

## 10. Python extractor (2026-10-23)

Both datasets are published to production (attention 1099511680819, vplus_delivery 1099511682098). The standalone
pipeline lives in the Windows clone at `vplus_deck/` (not synced; plain Python, key in a git-ignored `.env`).
`py -m vplus_deck extract --config config/10605.yaml` pulls report (13,834 rows), totals, delivery, flights and
served_by_ad into parquet in ~7 s and reconciles: 32,156 datapoints, 5.199657 vs network 5.233177 (-0.64%),
booked 3,316,875 / served 3,649,599 / bonus 332,724, cost 26,535.00, rate card 38,320.79, bonus value 11,785.79, CPM 8.00.
API facts: submit_query is async (job id) unless cached -> GET /jobs/{id} -> GET /jobs/{id}/result (result.data);
filter key is `values`; params are filtered like fields; booleans accepted. Next: roll-up module + deck builder.

## 11. Core deck builder (2026-10-23)

`py -m vplus_deck build --config config/10605.yaml` fills `vplus_deck/templates/core_sample.pptx` (the user's Core
template, Toronto Palapa Tours sample): slide 1 client + flight dates, 4 delivery summary, 5 highlights (avg, active
attention donut, top gender/age/location, arrows flipped when negative, province map from GeoJSON, markets tiles, top
creative thumbnail), 6 ad stack (table rows resized to N creatives, thumbnails, green/black vs network), 7 attention
over time (Plotly, vs campaign when below network else vs network), 8 demographic cards (Plotly). Shapes are addressed by
index and verified against the sample text; everything is resolved before any mutation (removals shift indexes).
Modules: rollup.py (weighted averages, markets, top demographic with >=20 obs, ad stack, daily, commentary),
deck_charts.py, deck.py. Tests: tests/test_rollup_10605.py (8 tests, pinned to the baseline). REVIEW.md lists manual
items: creative display names (config creative_names), slide 4 photo, map pins, slides 2/3/9-11 untouched.
Known gaps: ad names are ids (elev8_ads_ads names are codes); screen count = screens with attention (21), not active screens.

**2026-10-26:** full maintainer documentation is in the Windows clone at vplus_deck/DEVELOPER_GUIDE.md (datasets, metrics, id spaces, package modules, template map, change procedures) with vplus_deck/CHANGELOG.md. The vplus AML files (models/vplus_*, properties, screens, creative_img, datasets/vplus_delivery, dashboards/vplus_report_extract) were still untracked in git here; commit them.

## 12. One control for two datasets (2026-11-27)

Correction to section 2 ("a dimension-sourced filter does NOT feed a param"): that holds for the default wiring only.
With an explicit `interactions: [ FilterInteraction { from: '<control>' to: [ CustomMapping { block: [...] field: r(...) } ] } ]`
one FilterBlock can be mapped to a different field per block, across datasets, and the mapping DOES reach a param.
Confirmed by the user in the UI with two test copies of the Core Dashboard (both directions worked: a control sourced
from `attention_base.report_filter` mapped to `vplus_flight_facts.campaign_id`, and a control sourced from
`vplus_flight_facts.campaign_id` mapped to the param). `dashboards/core_dashboard.page.aml` uses the second form:
one Flight ID control (`f_flight`) drives the `vplus_delivery` blocks by dimension and the `attention` blocks by param.
`execute_viz_block` still ignores dashboard controls, so this can only be checked in the UI.
