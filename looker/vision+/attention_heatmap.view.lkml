
view: attention_heatmap {
  derived_table: {
    sql:
    (
SELECT
frames.*,
gender,
age_group
FROM `tech-data-warehouse.data_pipeline.stg_attention_ad_frames` frames
INNER JOIN
${detection_demography.SQL_TABLE_NAME} demo
ON frames.uuid = demo.uuid
WHERE attentive_frame = 1
AND       {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %}
      );;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }

  dimension_group: start_at_utc {
    type: time
    sql: ${TABLE}.start_at_utc ;;
  }

  dimension: display_id {
    type: string
    sql: ${TABLE}.display_id ;;
  }

  dimension: property_id {
    type: number
    sql: ${TABLE}.property_id ;;
  }

  dimension: screen {
    type: number
    sql: ${TABLE}.screen ;;
  }

  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  dimension: duration {
    type: number
    sql: ${TABLE}.duration ;;
  }

  dimension: start {
    type: number
    sql: ${TABLE}.start ;;
  }

  dimension: end {
    type: number
    sql: ${TABLE}.`end` ;;
  }

  dimension: attentive_frame {
    type: number
    sql: ${TABLE}.attentive_frame ;;
  }

  dimension: full_exposure {
    type: number
    sql: ${TABLE}.full_exposure ;;
  }

  dimension: attentive_startend_frames {
    type: number
    sql: ${TABLE}.attentive_startend_frames ;;
  }

  dimension: attentive_first_frames {
    type: number
    sql: ${TABLE}.attentive_first_frames ;;
  }

  dimension: attentive_last_frames {
    type: number
    sql: ${TABLE}.attentive_last_frames ;;
  }

  dimension: attentive_last_3_seconds {
    type: number
    sql: ${TABLE}.attentive_last_3_seconds ;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }



  set: detail {
    fields: [
      uuid,
      start_at_utc_time,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      duration,
      start,
      end,
      attentive_frame,
      full_exposure,
      attentive_startend_frames,
      attentive_first_frames,
      attentive_last_frames,
      attentive_last_3_seconds,
      gender,
      age_group
    ]
  }
}
