
view: attention_seconds {
  derived_table: {
    sql: SELECT
      attention.*,
      demo.gender,
      demo.gender_pie,
      demo.age_group,
      demo.generation,
      demo.gender_v2,
      case
      when attention_seconds_true >= 2.5 then 'Message Exposure'
      when attention_seconds_true < 2.5 then 'Brand Exposure'
      else ''
      end as exposure_category,
      campaigns.report_code,
      CASE
    -- Atlantic Time (Includes DST)
    WHEN address_province IN ('NS', 'NB', 'PE', 'Nova Scotia', 'New Brunswick', 'Prince Edward Island')
        THEN DATETIME(start_at_utc, 'America/Halifax')
    -- Newfoundland Time (Handles the unique 30-min offset + DST)
    WHEN address_province IN ('NL', 'Newfoundland and Labrador')
        THEN DATETIME(start_at_utc, 'America/St_Johns')
    -- Eastern Time (Toronto/Montreal)
    WHEN address_province IN ('ON', 'QC', 'Ontario', 'Quebec')
        THEN DATETIME(start_at_utc, 'America/Toronto')
    -- Central Time (Winnipeg)
    WHEN address_province IN ('MB', 'Manitoba')
        THEN DATETIME(start_at_utc, 'America/Winnipeg')
    -- Saskatchewan (Correctly stays on CST year-round)
    WHEN address_province IN ('SK', 'Saskatchewan')
        THEN DATETIME(start_at_utc, 'America/Regina')
    -- Mountain Time (Edmonton/Calgary)
    WHEN address_province IN ('AB', 'NT', 'Alberta', 'Northwest Territories')
        THEN DATETIME(start_at_utc, 'America/Edmonton')
    -- Pacific Time (Vancouver)
    WHEN address_province IN ('BC', 'YT', 'British Columbia', 'Yukon')
        THEN DATETIME(start_at_utc, 'America/Vancouver')
    ELSE DATETIME(start_at_utc, 'UTC')
      END as start_at_local,
      --attention.ad_length as ad_length,
      case
      when ad_length between 5 and 7 then 5
      when ad_length between 8 and 12 then 10
      when ad_length between 13 and 16 then 15
      when ad_length between 17 and 22 then 20
      when ad_length between 28 and 32 then 30
      else ad_length
      end as ad_length_grouped,
      case
      when attention_seconds_true >= 1 then '>=1'
      when attention_seconds_true < 1 then '<1'
      else ''
      end as atleast_1_sec,
      case
      when attention_seconds_true >= 1.5 then '>=1.5'
      when attention_seconds_true < 1.5 then '<1.5'
      else ''
      end as atleast_1_5_sec,
      case
      when attention_seconds_true >= 2 then '>=2'
      when attention_seconds_true < 2 then '<2'
      else ''
      end as atleast_2_sec,
      ads_type,
      FROM
      `tech-data-warehouse.data_pipeline.attention_seconds` attention
      INNER JOIN
      ${detection_demography.SQL_TABLE_NAME} demo
      ON attention.uuid = demo.uuid
      LEFT JOIN
     `tech-data-warehouse.data_pipeline.raw_campaigns` campaigns
      ON attention.campaign_id = cast(campaigns.id as string)
      LEFT JOIN
      ${properties.SQL_TABLE_NAME} properties
      ON attention.property_id = properties.id
      LEFT JOIN (
      select
      distinct
      ad_id,
      content_type as ads_type from `data_pipeline.stg_campaigns`
      where content_type is not null
      ) content_type
      ON attention.ad_id = content_type.ad_id
      WHERE attention.ad_id IS NOT NULL and attention_seconds_true is NOT NULL
      AND
      {% condition filters.frame_scope_campaign_id %} attention.campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} attention.ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} campaigns.report_code {% endcondition %}
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

  dimension: generation {
    type: string
    sql: ${TABLE}.generation ;;
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

  dimension: atleast_1_sec {
    type: string
    sql: ${TABLE}.atleast_1_sec ;;
  }

  dimension: atleast_1_5_sec {
    type: string
    sql: ${TABLE}.atleast_1_5_sec ;;
  }

  dimension: atleast_2_sec {
    type: string
    sql: ${TABLE}.atleast_2_sec ;;
  }

  dimension: ads_type {
    type: string
    sql: ${TABLE}.ads_type ;;
  }


  measure: sum_attention_v2 {
    type: sum
    sql: ${TABLE}.attention_seconds_true ;;
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
      generation,
      atleast_1_sec,
      atleast_1_5_sec,
      atleast_2_sec,
      ads_type
    ]
  }
}
