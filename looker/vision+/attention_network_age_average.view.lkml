view: attention_network_age_average {
  derived_table: {
    sql: select
      age_group,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds_network.SQL_TABLE_NAME}
      group by
      age_group;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  measure: network_average {
    type: number
    sql: avg(${TABLE}.campaign_average) ;;
  }

  set: detail {
    fields: [
      age_group
    ]
  }
}
