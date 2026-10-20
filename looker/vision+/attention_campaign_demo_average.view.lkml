
view: attention_campaign_demo_average {
  derived_table: {
    sql: select
      gender,
      age_group,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds.SQL_TABLE_NAME}
      where
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %}
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

  dimension: campaign_average {
    type: number
    sql: ${TABLE}.campaign_average ;;
  }

  set: detail {
    fields: [
      campaign_average,
      age_group,
      gender
    ]
  }
}
