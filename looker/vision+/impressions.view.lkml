
view: impressions {
  derived_table: {
    sql: select
    case when report_code is not null then 'Direct'
    else 'Programmatic'
    end as campaign_type,
    *
    from `data_pipeline.plays_summary`
    WHERE
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %} ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension_group: date {
    type: time
    datatype: datetime
    sql: ${TABLE}.date ;;
  }

  dimension: report_code {
    type: string
    sql: ${TABLE}.report_code ;;
  }

  dimension: mac_address {
    type: string
    sql: ${TABLE}.mac_address ;;
  }

  dimension: campaign_type {
    type: string
    sql: ${TABLE}.campaign_type ;;
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
      mac_address,
      property_id,
      campaign_id,
      ad_id,
      impressions,
      campaign_type,
      report_code
    ]
  }
}
