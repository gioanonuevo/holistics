
view: attention_seconds_customer_view {
  derived_table: {
    sql: SELECT
      attention.*,
      demo.gender,
      demo.gender_pie,
      demo.age_group,
      demo.gender_v2,
      case
      when attention_seconds_true >= 2.5 then 'Message Exposure'
      when attention_seconds_true < 2.5 then 'Brand Exposure'
      else ''
      end as exposure_category,
      campaigns.report_code,
      CASE
      WHEN address_province = 'ON' then DATETIME_SUB(start_at_utc, INTERVAL 4 HOUR)
      WHEN address_province = 'AB' then DATETIME_SUB(start_at_utc, INTERVAL 6 HOUR)
      WHEN address_province = 'BC' then DATETIME_SUB(start_at_utc, INTERVAL 7 HOUR)
      WHEN address_province = 'QC' then DATETIME_SUB(start_at_utc, INTERVAL 4 HOUR)
      ELSE start_at_utc
      END as start_at_local,
      CASE
      WHEN address_province = 'ON' then DATETIME_SUB(start_at_utc, INTERVAL 4 HOUR)
      WHEN address_province = 'AB' then DATETIME_SUB(start_at_utc, INTERVAL 6 HOUR)
      WHEN address_province = 'BC' then DATETIME_SUB(start_at_utc, INTERVAL 7 HOUR)
      WHEN address_province = 'QC' then DATETIME_SUB(start_at_utc, INTERVAL 4 HOUR)
      ELSE start_at_utc
      END as date,
      COALESCE(attention.ad_length,pipeline_campaigns.ad_length) as ad_length,
      ad_length_grouped,
      campaign_lu.campaign_group,
      COALESCE(creative_lu.creative_group,'others') as creative_group,
      COALESCE(creative_lu.creative_group2,'others') as creative_group2
      FROM
      `tech-data-warehouse.data_pipeline.attention_seconds` attention
      INNER JOIN
      `data_pipeline.stg_client_dashboard_campaign_groups_lu` campaign_lu
      ON attention.campaign_id = cast(campaign_lu.campaign_id as string)
      LEFT JOIN
      ${creatives.SQL_TABLE_NAME} creative_lu
      ON attention.ad_id = creative_lu.ad_id
      INNER JOIN
      ${detection_demography.SQL_TABLE_NAME} demo
      ON attention.uuid = demo.uuid
      LEFT JOIN
     `raw_elev8_backend.raw_campaigns` campaigns
      ON attention.campaign_id = cast(campaigns.id as string)
      LEFT JOIN
      `raw_elev8_backend.raw_properties` properties
      ON attention.property_id = properties.id
      LEFT JOIN
      (select
      *,
      case
      when ad_length between 5 and 7 then 5
      when ad_length between 8 and 12 then 10
      when ad_length between 13 and 16 then 15
      when ad_length between 17 and 22 then 20
      when ad_length between 28 and 32 then 30
      else ad_length
      end as ad_length_grouped
      from `tech-data-warehouse.data_pipeline.stg_campaigns`
      ) pipeline_campaigns
      ON attention.ad_id = pipeline_campaigns.ad_id
      WHERE attention.ad_id IS NOT NULL and attention_seconds_true is NOT NULL
      AND LENGTH(attention.ad_id) in (5,6) --temporary filter to remove programmatic
      AND
      {% condition filters.frame_scope_campaign_id %} attention.campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} attention.ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} campaigns.report_code {% endcondition %} AND
      {% condition filters.frame_scope_campaign_group %} campaign_lu.campaign_group {% endcondition %} AND
      {% condition filters.frame_scope_creative_group %} creative_lu.creative_group {% endcondition %} AND
      {% condition filters.frame_scope_creative_group2 %} creative_lu.creative_group2 {% endcondition %}
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

  dimension_group: start_at_utc {
    type: time
    sql: ${TABLE}.start_at_utc ;;
  }

  dimension: device_id {
    type: string
    sql: ${TABLE}.device_id ;;
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

  measure: sum_attention {
    type: number
    sql: SUM(${TABLE}.attention_seconds_true) ;;
  }

  measure: average_attention {
    type: number
    sql: SUM(${TABLE}.attention_seconds_true)/${count} ;;
  }

  dimension: report_code {
    type: string
    sql: ${TABLE}.report_code ;;
  }

  measure: average_attention_table{
    group_label: "Attention for table"
    label: "Attention"
    type: number
    value_format_name: percent_2
    sql: ${average_attention} ;;
    # value = 1 sig = 0.5  -> 1
    # value = 0.2 sig = 0.5 -> Average
    # value = -1 sig = 0.5 -> -1
    # value = -0.2 sig = 0.5 -> Average
    # The code below is very strange.
    # The problem is with liquid.
    # Comparing abs_value to significance_threshold._value directly doesn't work.
    # Probably significance_threshold._value has a string value by default, so
    # converting it to a number by putting it through a math function (plus: 0) causes
    # it to become a number, and then comparison with another number works.
    html:
      {% assign abs_value = value | abs %}
        {% if value < 0 %}
          <span style="color: @{negative_colour}"> {{ rendered_value }} </span>
        {% else %}
          <span style="color: @{positive_colour}"> {{ rendered_value }} </span>
        {% endif %}
    ;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: gender_pie {
    type: string
    sql: ${TABLE}.gender_pie ;;
  }

  dimension: exposure_category {
    type: string
    sql: ${TABLE}.exposure_category ;;
  }

  dimension: gender_v2 {
    type: string
    sql: ${TABLE}.gender_v2 ;;
  }

  dimension_group: start_at_local {
    type: time
    sql: ${TABLE}.start_at_local ;;
  }

  dimension_group: date {
    type: time
    sql: ${TABLE}.date ;;
  }


  dimension: ad_length {
    type: number
    sql: ${TABLE}.ad_length ;;
  }

  dimension: ad_length_grouped {
    type: number
    sql: ${TABLE}.ad_length_grouped ;;
  }

  dimension: attention_tier {
    type: tier
    tiers: [0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10,10.5,11,11.5,12,12.5,13,13.5,14,14.5,15,15.5,16]
    style: interval
    sql: ${TABLE}.attention_seconds_true ;;
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
    sql: ${TABLE}.creative_group2 ;;
  }

  set: detail {
    fields: [
      uuid,
      start_at_utc_time,
      device_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      age_group,
      gender,
      gender_pie,
      exposure_category,
      report_code,
      ad_length,
      ad_length_grouped,
      attention_tier,
      campaign_group,
      creative_group,
      creative_group2
    ]
  }
}
