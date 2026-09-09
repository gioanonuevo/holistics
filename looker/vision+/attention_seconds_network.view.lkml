
view: attention_seconds_network {
  derived_table: {
    sql: SELECT
      attention.*,
      age_group,
      gender_pie,
      gender,
      generation,
      case
      when attention_seconds_true >= 3 then 'Message Exposure'
      when attention_seconds_true < 3 then 'Brand Exposure'
      else ''
      end as exposure_category,
      case
      when ad_length between 5 and 7 then 5
      when ad_length between 8 and 12 then 10
      when ad_length between 13 and 16 then 15
      when ad_length between 17 and 22 then 20
      when ad_length between 28 and 32 then 30
      else ad_length
      end as ad_length_grouped,
      FROM
      `tech-data-warehouse.data_pipeline.attention_seconds` attention
      LEFT JOIN
      ${properties.SQL_TABLE_NAME} properties
      ON attention.property_id = properties.id
      INNER JOIN
      ${detection_demography.SQL_TABLE_NAME} demo
      ON attention.uuid = demo.uuid
      INNER JOIN ${flight_date_range_clipping_helper_v.SQL_TABLE_NAME}
      on date(start_at_utc) = dates
      INNER JOIN ${ad_length_clipping_helper_v.SQL_TABLE_NAME}
      on
      case
      when ad_length between 5 and 7 then 5
      when ad_length between 8 and 12 then 10
      when ad_length between 13 and 16 then 15
      when ad_length between 17 and 22 then 20
      when ad_length between 28 and 32 then 30
      else ad_length
      end = ${ad_length_clipping_helper_v.SQL_TABLE_NAME}.ad_length_grouped
      INNER JOIN ${city_clipping_helper_v.SQL_TABLE_NAME}
      on properties.address_city = ${city_clipping_helper_v.SQL_TABLE_NAME}.properties_city
      WHERE attention.ad_id IS NOT NULL and attention_seconds_true is NOT NULL
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

  dimension: display_id {
    type: string
    sql: ${TABLE}.display_id ;;
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

  dimension: ad_length_grouped {
    type: string
    sql: ${TABLE}.ad_length_grouped ;;
  }

  dimension: ad_length {
    type: string
    sql: ${TABLE}.ad_length ;;
  }

  dimension: generation {
    type: string
    sql: ${TABLE}.generation ;;
  }

  set: detail {
    fields: [
      uuid,
      start_at_utc_time,
      display_id,
      property_id,
      screen,
      campaign_id,
      ad_id,
      age_group,
      gender,
      gender_pie,
      exposure_category,
      ad_length_grouped,
      ad_length,
      generation
    ]
  }
}
