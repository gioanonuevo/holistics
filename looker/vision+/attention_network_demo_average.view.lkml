
view: attention_network_demo_average {
  derived_table: {
    sql: select
      gender,
      age_group,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds_network.SQL_TABLE_NAME}
      group by
      gender,
      age_group;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  dimension: network_average {
    type: number
    sql: ${TABLE}.campaign_average ;;
  }

  set: detail {
    fields: [
      network_average,
      age_group,
      gender
    ]
  }
}
