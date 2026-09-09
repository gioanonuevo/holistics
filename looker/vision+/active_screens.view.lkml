
view: active_screens {
  derived_table: {
    sql: select * from `tech-data-warehouse.data_pipeline.active_screens` ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: id {
    type: string
    sql: ${TABLE}.id ;;
  }

  dimension: venue_id {
    type: string
    sql: ${TABLE}.venue_id ;;
  }

  dimension: property_id {
    type: string
    sql: ${TABLE}.property_id ;;
  }

  dimension: display_id {
    type: string
    sql: ${TABLE}.display_id ;;
  }

  dimension: screen_name {
    type: string
    sql: ${TABLE}.screen_name ;;
  }

  dimension: mac_address {
    type: string
    sql: ${TABLE}.mac_address ;;
  }

  dimension: property_name {
    type: string
    sql: ${TABLE}.property_name ;;
  }

  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
  }

  dimension: address {
    type: string
    sql: ${TABLE}.address ;;
  }

  dimension: property_type {
    type: string
    sql: ${TABLE}.property_type ;;
  }

  dimension: venue_openooh_category {
    type: string
    sql: ${TABLE}.venue_openooh_category ;;
  }

  dimension: dma {
    type: string
    sql: ${TABLE}.dma ;;
  }

  dimension: dma_rank {
    type: number
    sql: ${TABLE}.DMA_Rank ;;
  }

  dimension: reach {
    type: number
    sql: ${TABLE}.reach ;;
  }

  dimension: frequency {
    type: number
    sql: ${TABLE}.frequency ;;
  }

  dimension_group: last_seen_at {
    type: time
    sql: ${TABLE}.last_seen_at ;;
  }

  dimension: plays_last_30_days {
    type: number
    sql: ${TABLE}.plays_last_30_days ;;
  }

  set: detail {
    fields: [
      id,
      venue_id,
      property_id,
      display_id,
      screen_name,
      mac_address,
      property_name,
      country,
      city,
      address,
      property_type,
      venue_openooh_category,
      dma,
      dma_rank,
      reach,
      frequency,
      last_seen_at_time,
      plays_last_30_days
    ]
  }
}
