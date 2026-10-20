
view: vision_screen_monitoring {
  derived_table: {
    sql: select
      REPLACE(base.mac_address,":","-") as mac_address,
      LU.property_id,
      LU.property_name,
      LU.notes,
      latest_vision_date,
      latest_play_date,
      latest_attention_date,
      sum(vision_count) vision_count_last_two_weeks,
      sum(play_count) play_count_last_two_weeks,
      sum(attention_count) attention_count_last_two_weeks,
      case
      when sum(vision_count) = 0 and sum(play_count) > 0 then 'vision error'
      when sum(vision_count) > 0 and sum(play_count) = 0 then 'play error'
      when sum(vision_count) = 0 and sum(play_count) = 0 then 'offline'
      when sum(vision_count) > 0 and sum(play_count) > 0 then 'online'
      else ''
      end as status,
      case
      when sum(vision_count) > 0 and sum(play_count) > 0 and sum(attention_count) = 0 then 'online but no attention data'
      else ''
      end as attention_status
      from `data_pipeline.vision_screen_event_monitoring` base
      LEFT JOIN (
      select * from `data_pipeline.vision_screen_latest_data_date`
      ) date_lu
      ON base.mac_address = date_lu.mac_address
      INNER JOIN
      (SELECT
      string_field_0 as mac_address,
      string_field_1 as property_id,
      string_field_2 as property_name,
      string_field_3 as notes
      FROM `tech-data-warehouse.uploads.vision_screen_base`) LU
      ON base.mac_address = LU.mac_address
      where
      date >= current_date - 15
      group by 1,2,3,4,5,6,7 ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: mac_address {
    type: string
    sql: ${TABLE}.mac_address ;;
  }

  dimension: property_id {
    type: string
    sql: ${TABLE}.property_id ;;
  }

  dimension: property_name {
    type: string
    sql: ${TABLE}.property_name ;;
  }

  dimension: notes {
    type: string
    sql: ${TABLE}.notes ;;
  }

  dimension: latest_vision_date {
    type: date
    datatype: date
    sql: ${TABLE}.latest_vision_date ;;
  }

  dimension: latest_play_date {
    type: date
    datatype: date
    sql: ${TABLE}.latest_play_date ;;
  }

  dimension: latest_attention_date {
    type: date
    datatype: date
    sql: ${TABLE}.latest_attention_date ;;
  }

  dimension: vision_count_last_two_weeks {
    type: number
    sql: ${TABLE}.vision_count_last_two_weeks ;;
  }

  dimension: play_count_last_two_weeks {
    type: number
    sql: ${TABLE}.play_count_last_two_weeks ;;
  }

  dimension: attention_count_last_two_weeks {
    type: number
    sql: ${TABLE}.attention_count_last_two_weeks ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: attention_status {
    type: string
    sql: ${TABLE}.attention_status ;;
  }

  set: detail {
    fields: [
      mac_address,
      property_id,
      property_name,
      notes,
      latest_vision_date,
      latest_play_date,
      latest_attention_date,
      vision_count_last_two_weeks,
      play_count_last_two_weeks,
      attention_count_last_two_weeks,
      status,
      attention_status
    ]
  }
}
