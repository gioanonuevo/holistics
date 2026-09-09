
view: screen_monitoring_programmatic_play_events {
  derived_table: {
    sql: select distinct *,
      case when play_events > 0 then 'With Events'
      else 'No Events'
      end as play_status
      FROM `data_pipeline.screen_monitoring_programmaticplays_v`
       ;;
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

  dimension: mac_address {
    type: string
    sql: ${TABLE}.mac_address ;;
  }

  dimension: impression_type {
    type: string
    sql: ${TABLE}.impression_type ;;
  }

  dimension: play_status {
    type: string
    sql: ${TABLE}.play_status ;;
  }

  measure: play_events {
    type: sum
    sql: ${TABLE}.play_events ;;
  }

  set: detail {
    fields: [
      date,
      mac_address,
      impression_type,
      play_status,
      play_events
    ]
  }
}
