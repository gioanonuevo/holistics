
view: us_sales {
  derived_table: {
    sql: SELECT *,
      format_date('%B', date(2020, Month, 1)) as month_name
      FROM `tech-data-warehouse.uploads.vistar_us_sales`
      where year is not NULL
      ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: year {
    type: number
    sql: ${TABLE}.Year ;;
  }

  dimension: month {
    type: number
    sql: ${TABLE}.Month ;;
  }

  dimension: ad_exchange {
    type: string
    sql: ${TABLE}.Ad_Exchange ;;
  }

  dimension: buyer {
    type: string
    sql: ${TABLE}.Buyer ;;
  }

  dimension: bidder {
    type: string
    sql: ${TABLE}.Bidder_Name ;;
  }


  dimension: advertiser {
    type: string
    sql: ${TABLE}.Advertiser ;;
  }

  dimension: venue_type {
    type: string
    sql: ${TABLE}.Venue_Type ;;
  }

  dimension: dma {
    type: string
    sql: ${TABLE}.DMA ;;
  }

  measure: impressions {
    type: number
    sql: SUM(${TABLE}.Impressions) ;;
  }

  dimension: spots {
    type: number
    sql: ${TABLE}.Spots ;;
  }

  measure: revenue {
    type: number
    sql: SUM(${TABLE}.Revenue) ;;
  }

  dimension: e_cpm {
    type: number
    sql: ${TABLE}.eCPM ;;
  }

  dimension: data_e_cpm {
    type: number
    sql: ${TABLE}.Data_eCPM ;;
  }

  dimension: data_cost {
    type: number
    sql: ${TABLE}.Data_Cost ;;
  }

  dimension: profit {
    type: number
    sql: ${TABLE}.Profit ;;
  }

  dimension: month_name {
    type: string
    sql: ${TABLE}.month_name ;;
  }

  set: detail {
    fields: [
      year,
      month,
      ad_exchange,
      buyer,
      bidder,
      advertiser,
      venue_type,
      dma,
      impressions,
      spots,
      revenue,
      e_cpm,
      data_e_cpm,
      data_cost,
      profit,
      month_name
    ]
  }
}
