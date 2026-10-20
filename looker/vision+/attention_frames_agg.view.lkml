
view: attention_frames_agg {
  derived_table: {
    sql: select
            uuid,
            display_id,
            property_id,
            screen,
            campaign_id,
            ad_id,
            full_exposure,
            avg(duration) as ad_duration,
            sum(attentive_frame) as sum_attentive_frames,
            sum(attentive_frame) / 2 / avg(duration) as perc_viewed,
            sum(attentive_startend_frames) as sum_attentive_startend_frames,
            sum(attentive_first_frames) as sum_attentive_first_frames,
            sum(attentive_last_frames) as sum_attentive_last_frames,
            case when sum(attentive_startend_frames) = 4 then 1 else 0 end as video_completion_flag,
            case when sum(attentive_first_frames) = 2 then 1 else 0 end as video_started_flag,
            case when sum(attentive_last_frames) = 2 then 1 else 0 end as video_ended_flag,
            case when sum(attentive_last_frames) >= 1 and sum(attentive_first_frames) >= 1 then 1 else 0 end as video_completion_flag_05,
            FROM
            (
            SELECT
            *
            FROM
            `tech-data-warehouse.data_pipeline.stg_attention_ad_frames` frames
            )
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
            full_exposure
            ;;
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
    type: number
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: ad_id {
    type: number
    sql: ${TABLE}.ad_id ;;
  }

  dimension: ad_duration {
    type: number
    sql: ${TABLE}.ad_duration ;;
  }

  dimension: sum_attentive_frames {
    type: number
    sql: ${TABLE}.sum_attentive_frames ;;
  }

  dimension: perc_viewed {
    type: number
    sql: ${TABLE}.perc_viewed ;;
  }

  dimension: sum_attentive_startend_frames {
    type: number
    sql: ${TABLE}.sum_attentive_startend_frames ;;
  }

  dimension: sum_attentive_first_frames {
    type: number
    sql: ${TABLE}.sum_attentive_first_frames ;;
  }

  dimension: sum_attentive_last_frames {
    type: number
    sql: ${TABLE}.sum_attentive_last_frames ;;
  }

  dimension: video_completion_flag {
    type: number
    sql: ${TABLE}.video_completion_flag ;;
  }

  dimension: video_started_flag {
    type: number
    sql: ${TABLE}.video_started_flag ;;
  }

  dimension: video_ended_flag {
    type: number
    sql: ${TABLE}.video_ended_flag ;;
  }

  dimension: video_completion_flag_05 {
    type: number
    sql: ${TABLE}.video_completion_flag_05 ;;
  }

  dimension: full_exposure {
    type: number
    sql: ${TABLE}.full_exposure ;;
  }

  set: detail {
    fields: [
      uuid,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      ad_duration,
      sum_attentive_frames,
      perc_viewed,
      full_exposure,
      sum_attentive_startend_frames,
      sum_attentive_first_frames,
      sum_attentive_last_frames,
      video_completion_flag,
      video_started_flag,
      video_ended_flag
    ]
  }
}
