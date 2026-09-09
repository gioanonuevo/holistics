
view: attention_creative_average {
  derived_table: {
    sql: select
      ad_id,
      avg(attention_seconds_true) as creative_average
      from ${attention_seconds.SQL_TABLE_NAME}
      where
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %}
      group by
      1;;
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  measure: creative_average {
    type: number
    sql: avg(${TABLE}.creative_average) ;;
  }

  set: detail {
    fields: [
    ]
  }
}
