
view: creatives {
  derived_table: {
    sql: select
      campaigns.*,
      campaign_group,
      creative_group,
      creative_group2
      from `data_pipeline.stg_campaigns` campaigns
      left join
      `data_pipeline.stg_client_dashboard_campaign_groups_lu` campaign_groups
      ON
      campaigns.campaign_id = CAST(campaign_groups.campaign_id as string)
      left join
      `data_pipeline.stg_client_dashboard_creative_groups_lu` creative_groups
      ON
      campaigns.ad_id = creative_groups.creative_id ;;
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

  dimension_group: start_at {
    type: time
    sql: ${TABLE}.start_at ;;
  }

  dimension_group: end_at {
    type: time
    sql: ${TABLE}.end_at ;;
  }

  dimension: content_type {
    type: string
    sql: ${TABLE}.content_type ;;
  }

  dimension: campaign_group {
    type: string
    sql: ${TABLE}.campaign_group ;;
  }

  dimension: creative_group {
    type: string
    sql: ${TABLE}.creative_group ;;
  }

  dimension: creative_group2 {
    type: string
    sql: ${TABLE}.creative_group ;;
  }

  set: detail {
    fields: [
      campaign_id,
      report_code,
      ad_id,
      advertiser,
      ad_length,
      start_at_time,
      end_at_time,
      content_type,
      campaign_group,
      creative_group,
      creative_group2
    ]
  }
}
