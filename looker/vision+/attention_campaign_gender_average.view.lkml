
view: attention_campaign_gender_average {
  derived_table: {
    sql: select
      gender,
      avg(attention_seconds_true) as campaign_average
      from ${attention_seconds.SQL_TABLE_NAME}
      where
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %}
      group by
      gender;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: campaign_average {
    type: number
    sql: ${TABLE}.campaign_average ;;
  }

  set: detail {
    fields: [
      campaign_average,
      gender
    ]
  }
}
