# Partition pruning query tests

These tests compare query shapes for Vertical City's campaign-derived flight-date filtering on `data_pipeline.attention_seconds_v2`.

| # | Test purpose | Query shape | Bytes scanned |
|---:|---|---|---:|
| 1 | Test dynamic min/max bounds derived from campaign | `campaign_id` → `MIN(start_at)` / `MAX(end_at)` CTE → `WHERE DATE(attention.start_at_utc) >= min_date AND <= max_date` | 8,200,129.17 MiB |
| 2 | Test Looker-style helper-date join | `campaign_id` → generate distinct flight dates → `INNER JOIN` on `DATE(attention.start_at_utc) = helper_date` | 238,129.10 MiB |
| 3 | Baseline literal date filter | literal `DATE '2026-08-12'` to `DATE '2026-09-14'` → `WHERE DATE(attention.start_at_utc) BETWEEN ...` | 232,247.40 MiB |
| 4 | Re-test helper-date join against literal baseline | same helper-date equality join as query 2 | 238,129.10 MiB |

## Query 1: dynamic min/max bounds derived from campaign

```sql
#standardsql
WITH creatives AS (
  SELECT
    campaigns.*,
    campaign_group,
    creative_group,
    creative_group2
  FROM `data_pipeline.stg_campaigns` AS campaigns
  LEFT JOIN `data_pipeline.stg_client_dashboard_campaign_groups_lu` AS campaign_groups
    ON campaigns.campaign_id = CAST(campaign_groups.campaign_id AS STRING)
  LEFT JOIN `data_pipeline.stg_client_dashboard_creative_groups_lu` AS creative_groups
    ON campaigns.ad_id = creative_groups.creative_id
),
flight_date_bounds AS (
  SELECT
    MIN(DATE(start_at)) AS minimum_flight_date,
    MAX(DATE(end_at)) AS maximum_flight_date
  FROM creatives
  WHERE CAST(campaign_id AS STRING) = '10604'
)
SELECT
  a.uuid AS dpasv_u_bee2c9,
  a.start_at_utc AS dpasv_sau_5cdb72
FROM `data_pipeline.attention_seconds_v2` AS a
CROSS JOIN flight_date_bounds AS b
WHERE DATE(a.start_at_utc) >= b.minimum_flight_date
  AND DATE(a.start_at_utc) <= b.maximum_flight_date
GROUP BY
  1, 2
LIMIT 10;
```

Bytes scanned: **8,200,129.17 MiB**

## Query 2: Looker-style helper-date equality join

```sql
#standardsql
WITH creatives AS (
  SELECT
    campaigns.*,
    campaign_group,
    creative_group,
    creative_group2
  FROM `data_pipeline.stg_campaigns` AS campaigns
  LEFT JOIN `data_pipeline.stg_client_dashboard_campaign_groups_lu` AS campaign_groups
    ON campaigns.campaign_id = CAST(campaign_groups.campaign_id AS STRING)
  LEFT JOIN `data_pipeline.stg_client_dashboard_creative_groups_lu` AS creative_groups
    ON campaigns.ad_id = creative_groups.creative_id
),
flight_dates AS (
  SELECT DISTINCT date_value
  FROM (
    SELECT
      DATE(start_at) AS start_date,
      DATE(end_at) AS end_date
    FROM creatives
    WHERE CAST(campaign_id AS STRING) = '10604'
  ),
  UNNEST(GENERATE_DATE_ARRAY(start_date, end_date)) AS date_value
)
SELECT
  a.uuid AS dpasv_u_bee2c9,
  a.start_at_utc AS dpasv_sau_5cdb72
FROM `data_pipeline.attention_seconds_v2` AS a
INNER JOIN flight_dates AS f
  ON DATE(a.start_at_utc) = f.date_value
GROUP BY
  1, 2
LIMIT 10;
```

Bytes scanned: **238,129.10 MiB**

## Query 3: literal date range baseline

```sql
#standardsql
SELECT
  a.uuid AS dpasv_u_bee2c9,
  a.start_at_utc AS dpasv_sau_5cdb72
FROM `data_pipeline.attention_seconds_v2` AS a
WHERE DATE(a.start_at_utc) >= DATE '2026-08-12'
  AND DATE(a.start_at_utc) <= DATE '2026-09-14'
GROUP BY
  1, 2
LIMIT 10;
```

Bytes scanned: **232,247.40 MiB**

## Query 4: helper-date equality join re-test

```sql
#standardsql
WITH creatives AS (
  SELECT
    campaigns.*,
    campaign_group,
    creative_group,
    creative_group2
  FROM `data_pipeline.stg_campaigns` AS campaigns
  LEFT JOIN `data_pipeline.stg_client_dashboard_campaign_groups_lu` AS campaign_groups
    ON campaigns.campaign_id = CAST(campaign_groups.campaign_id AS STRING)
  LEFT JOIN `data_pipeline.stg_client_dashboard_creative_groups_lu` AS creative_groups
    ON campaigns.ad_id = creative_groups.creative_id
),
flight_dates AS (
  SELECT DISTINCT date_value
  FROM (
    SELECT
      DATE(start_at) AS start_date,
      DATE(end_at) AS end_date
    FROM creatives
    WHERE CAST(campaign_id AS STRING) = '10604'
  ),
  UNNEST(GENERATE_DATE_ARRAY(start_date, end_date)) AS date_value
)
SELECT
  a.uuid AS dpasv_u_bee2c9,
  a.start_at_utc AS dpasv_sau_5cdb72
FROM `data_pipeline.attention_seconds_v2` AS a
INNER JOIN flight_dates AS f
  ON DATE(a.start_at_utc) = f.date_value
GROUP BY
  1, 2
LIMIT 10;
```

Bytes scanned: **238,129.10 MiB**
