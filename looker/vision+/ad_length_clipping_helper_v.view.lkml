
view: ad_length_clipping_helper_v {
  derived_table: {
    sql: with ad_length_lookup as (
      select ad_length,
      case
      when ad_length between 5 and 7 then 5
      when ad_length between 8 and 12 then 10
      when ad_length between 13 and 16 then 15
      when ad_length between 17 and 22 then 20
      when ad_length between 28 and 32 then 30
      else ad_length
      end as ad_length_grouped
      from ${creatives.SQL_TABLE_NAME}
      where
      --{% condition filters.frame_scope_flight_id %} id {% endcondition %}
      {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} report_code {% endcondition %} AND
      {% condition filters.frame_scope_campaign_group %} campaign_group {% endcondition %} AND
      {% condition filters.frame_scope_creative_group %} creative_group {% endcondition %} AND
      {% condition filters.frame_scope_creative_group2 %} creative_group2 {% endcondition %}
      )

      select distinct ad_length_grouped from ad_length_lookup ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: ad_length_grouped {
    type: number
    sql: ${TABLE}.ad_length_grouped ;;
  }

  set: detail {
    fields: [
      ad_length_grouped
    ]
  }
}
