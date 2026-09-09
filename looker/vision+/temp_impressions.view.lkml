
view: temp_impressions {
  derived_table: {
    sql: SELECT * FROM `tech-data-warehouse.data_pipeline.temp_impressions`
          WHERE
            length(campaign_id) = 4 AND
            {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
            {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
            {% condition filters.frame_scope_report_id %} report_code {% endcondition %} ;;
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

  dimension: system {
    type: string
    sql: ${TABLE}.system ;;
  }

  dimension: mac_address {
    type: string
    sql: ${TABLE}.mac_address ;;
  }

  dimension: property_id {
    type: number
    sql: ${TABLE}.property_id ;;
  }

  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  measure: impressions {
    type: number
    sql: SUM(${TABLE}.impressions) ;;
  }

  set: detail {
    fields: [
      date,
      mac_address,
      system,
      property_id,
      campaign_id,
      ad_id,
      impressions
    ]
  }
}
