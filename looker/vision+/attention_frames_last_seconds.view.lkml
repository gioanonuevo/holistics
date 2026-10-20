
view: attention_frames_last_seconds {
  derived_table: {
    sql: SELECT
      ad_frames.uuid,
      campaign_id,
      ad_id,
      age_group,
      gender,
      sum(attentive_key_moment) as attentive_key_moment
      FROM (
      SELECT
      *
      FROM `tech-data-warehouse.data_pipeline.stg_attention_ad_frames` frames
      WHERE attentive_frame = 1
      ) ad_frames
      INNER JOIN
      ${detection_demography.SQL_TABLE_NAME} demo
      ON ad_frames.uuid = demo.uuid
      WHERE
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %}
      group by
      uuid,
      campaign_id,
      ad_id,
      age_group,
      gender;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }

  dimension: campaign_id {
    type: number
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: ad_id {
    type: number
    sql: ${TABLE}.ad_id ;;
  }

  dimension: attentive_key_moment {
    type: number
    sql: ${TABLE}.attentive_key_moment ;;
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
      campaign_id,
      ad_id,
      attentive_key_moment,
      age_group,
      gender
    ]
  }
}
