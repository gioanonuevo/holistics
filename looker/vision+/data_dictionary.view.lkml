
view: data_dictionary {
  derived_table: {
    sql: select
      *
      from
      tech-data-warehouse.uploads.stg_data_dictionary
       ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: metric {
    type: string
    sql: ${TABLE}.metric ;;
  }

  dimension: definition {
    type: string
    sql: ${TABLE}.definition ;;
  }

  set: detail {
    fields: [
      metric,
      definition
    ]
  }
}
