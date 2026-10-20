
view: attention_network_average {
  derived_table: {
    sql: select
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds_network.SQL_TABLE_NAME} ;;
  }

  measure: network_average {
    type: number
    sql: avg(${TABLE}.campaign_average) ;;
  }

  set: detail {
    fields: [
    ]
  }
}
