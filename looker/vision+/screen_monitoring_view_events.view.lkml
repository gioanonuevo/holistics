
view: screen_monitoring_view_events {
  derived_table: {
    sql: select *,
      case when vision_events > 0 then 'With Events'
      else 'No Events'
      end as vision_status
      from`tech-data-warehouse.data_pipeline.screen_monitoring_vision_events_v` ;;
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

  dimension: vision_status {
    type: string
    sql: ${TABLE}.vision_status ;;
  }

  measure: vision_events {
    type: sum
    sql: ${TABLE}.vision_events ;;
  }

  set: detail {
    fields: [
      date,
      mac_address,
      vision_status
    ]
  }
}
