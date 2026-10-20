
view: attention_retention {
  derived_table: {
    sql: SELECT
      uuid,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      duration,
      start,
      first_frames.end,
      full_exposure,
      sum(attentive_frame) as attentive_frames
      FROM(
      SELECT
      A.*
      FROM `tech-data-warehouse.data_pipeline.attention_ad_frames` A
      inner join
      (select
      distinct
      uuid,
      ad_id
      FROM `tech-data-warehouse.data_pipeline.attention_ad_frames`
       where start in (0.0) and attentive_first_frames = 1
      ) B
      ON A.uuid = B.uuid and A.ad_id = B.ad_id
      ) first_frames
      WHERE
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %}
      group by
      uuid,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      duration,
      start,
      first_frames.end,
      full_exposure ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
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

  dimension: full_exposure {
    type: number
    sql: ${TABLE}.full_exposure ;;
  }

  dimension: attentive_frames {
    type: number
    sql: ${TABLE}.attentive_frames ;;
  }

  set: detail {
    fields: [
      uuid,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      duration,
      start,
      end,
      full_exposure,
      attentive_frames
    ]
  }
}
