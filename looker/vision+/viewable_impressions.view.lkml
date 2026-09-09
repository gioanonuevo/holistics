
view: viewable_impressions {
  derived_table: {
    sql: SELECT
      plays.*,
      attention_seconds
      FROM
      (
      select
      ad_start as date,
      display_id,
      campaign_id,
      ad_id,
      sum(detected_count) as plays_with_detection
      from `data_pipeline.plays_detection1`
      group by
      1,
      2,
      3,
      4
      ) plays
      LEFT JOIN
      (select
      date(start_at_utc) as date,
      display_id,
      campaign_id,
      ad_id,
      sum(attention_seconds_true) as attention_seconds
      from `data_pipeline.attention_seconds`
      group by
      1,
      2,
      3,
      4) attention
      ON
      plays.date = attention.date
      AND plays.display_id = attention.display_id
      AND plays.campaign_id = attention.campaign_id
      AND plays.ad_id = attention.ad_id
      WHERE
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %};;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: date {
    type: date
    datatype: date
    sql: ${TABLE}.date ;;
  }

  dimension: display_id {
    type: string
    sql: ${TABLE}.display_id ;;
  }

  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  measure: plays_with_detection {
    type: number
    sql: SUM(${TABLE}.plays_with_detection) ;;
  }

  measure: attention_seconds {
    type: number
    sql: SUM(${TABLE}.attention_seconds) ;;
  }

  set: detail {
    fields: [
      date,
      display_id,
      campaign_id,
      ad_id,
      plays_with_detection,
      attention_seconds
    ]
  }
}
