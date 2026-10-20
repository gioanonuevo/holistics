
view: attention_network_generation_average {
  derived_table: {
    sql: select
      generation,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds_network.SQL_TABLE_NAME}
      group by
      generation ;;
  }

  dimension: generation {
    type: string
    sql: ${TABLE}.generation ;;
  }

  measure: network_average {
    type: number
    sql: avg(${TABLE}.campaign_average) ;;
  }

  set: detail {
    fields: [
      generation
    ]
  }
}
