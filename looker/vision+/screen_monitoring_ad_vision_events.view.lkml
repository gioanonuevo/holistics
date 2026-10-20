
view: screen_monitoring_ad_vision_events {
  derived_table: {
    sql: select
      *,
      case when vision_ad_event > 0 then 'With Events'
      else 'No Events'
      end as status
      FROM `data_pipeline.screen_monitoring_vision_ad_events`
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

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  measure: vision_ad_event {
    type: sum
    sql: ${TABLE}.vision_ad_event ;;
  }

  set: detail {
    fields: [
      date,
      mac_address,
      status,
      vision_ad_event
    ]
  }
}
