
view: attention_campaign_age_average {
  derived_table: {
    sql: select
      age_group,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds.SQL_TABLE_NAME}
      where
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %}
      group by
      age_group;;
  }

  dimension: age_group {
    type: string
    sql: ${TABLE}.age_group ;;
  }

  measure: campaign_average {
    type: number
    sql: avg(${TABLE}.campaign_average) ;;
  }

  set: detail {
    fields: [
      age_group
    ]
  }
}
