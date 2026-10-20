
view: detection_demography {
  derived_table: {
    sql:
      select
      *
      FROM
      `tech-data-warehouse.data_pipeline.detection_demography`
      where age_group not in ('18 below','no info') ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }

  dimension: male_confidence {
    type: string
    sql: ${TABLE}.male_confidence ;;
  }

  dimension: female_confidence {
    type: string
    sql: ${TABLE}.female_confidence ;;
  }

  dimension: gender_pie {
    type: string
    sql: ${TABLE}.gender_pie ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: n_snapshot {
    type: number
    sql: ${TABLE}.n_snapshot ;;
  }

  dimension: mean_age {
    type: number
    sql: ${TABLE}.mean_age ;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  dimension: generation {
    type: string
    sql: ${TABLE}.generation ;;
  }

  dimension: gender_v2 {
    type: string
    sql: ${TABLE}.gender_v2 ;;
  }


  set: detail {
    fields: [
      uuid,
      male_confidence,
      female_confidence,
      gender_pie,
      gender,
      generation,
      n_snapshot,
      mean_age,
      age_group,
      gender_v2
    ]
  }
}
