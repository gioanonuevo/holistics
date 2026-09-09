
view: demographics_lookup {
  derived_table: {
    sql: SELECT
      a.uuid,
      n_snapshot,
      mean_age as age,
      male_confidence,
      female_confidence,
      gender
      FROM `tech-data-warehouse.data_pipeline.stg_detection_age` a
      FULL OUTER JOIN `tech-data-warehouse.data_pipeline.stg_detection_gender` b on a.uuid = b.uuid ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }

  dimension: n_snapshot {
    type: number
    sql: ${TABLE}.n_snapshot ;;
  }

  dimension: age {
    type: number
    sql: ${TABLE}.age ;;
  }

  dimension: male_confidence {
    type: string
    sql: ${TABLE}.male_confidence ;;
  }

  dimension: female_confidence {
    type: string
    sql: ${TABLE}.female_confidence ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  set: detail {
    fields: [
      uuid,
      n_snapshot,
      age,
      male_confidence,
      female_confidence,
      gender
    ]
  }
}
