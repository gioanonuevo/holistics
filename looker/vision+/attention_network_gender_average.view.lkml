
view: attention_network_gender_average {
  derived_table: {
    sql: select
      gender,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds_network.SQL_TABLE_NAME}
      group by
      gender ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: network_average {
    type: number
    sql: ${TABLE}.campaign_average ;;
  }

  set: detail {
    fields: [
      network_average,
      gender
    ]
  }
}
