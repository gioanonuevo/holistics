
view: attention_campaign_average {
  derived_table: {
    sql: select
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds.SQL_TABLE_NAME}
      where
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %} ;;
  }

  measure: campaign_average {
    type: number
    sql: avg(${TABLE}.campaign_average) ;;
  }

  set: detail {
    fields: [
    ]
  }
}
