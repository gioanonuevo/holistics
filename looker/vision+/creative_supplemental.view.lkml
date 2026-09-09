
view: creative_supplemental {
  derived_table: {
    sql: SELECT * FROM `tech-data-warehouse.uploads.creative_supplemental_data` ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: flight_id {
    type: string
    sql: ${TABLE}.flight_id ;;
  }

  dimension: creative_id {
    type: string
    sql: ${TABLE}.creative_id ;;
  }

  dimension: industry {
    type: string
    sql: ${TABLE}.industry ;;
  }

  dimension: media_type {
    type: string
    sql: ${TABLE}.media_type ;;
  }

  dimension: qr_enabled {
    type: yesno
    sql: ${TABLE}.QR_Enabled ;;
  }

  dimension: colors {
    type: string
    sql: ${TABLE}.Colors ;;
  }

  dimension: offer {
    type: yesno
    sql: ${TABLE}.Offer_ ;;
  }

  set: detail {
    fields: [
      flight_id,
      creative_id,
      industry,
      media_type,
      qr_enabled,
      colors,
      offer
    ]
  }
}
