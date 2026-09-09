
view: campaign_details {
  derived_table: {
    sql: select * from `tech-data-warehouse.data_pipeline.stg_campaigns` ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: report_code {
    type: string
    sql: ${TABLE}.report_code ;;
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  dimension: advertiser {
    type: string
    sql: ${TABLE}.advertiser ;;
  }

  dimension: ad_length {
    type: number
    sql: ${TABLE}.ad_length ;;
  }

  dimension: content_type {
    type: string
    sql: ${TABLE}.content_type ;;
  }

  dimension_group: start_at {
    type: time
    sql: ${TABLE}.start_at ;;
  }

  dimension_group: end_at {
    type: time
    sql: ${TABLE}.end_at ;;
  }

  set: detail {
    fields: [
      campaign_id,
      report_code,
      ad_id,
      advertiser,
      ad_length,
      content_type,
      start_at_time,
      end_at_time
    ]
  }
}
