view: attention_fatigue {

    derived_table: {
      sql:    select
              start_at_local,
              fatigue.ad_id,
              fatigue_cutoff_date,
              creative_average,
              average_attention,
              datapoints,
              case when date(start_at_local) > date(fatigue_cutoff_date) and creative_average > average_attention then 1
              else 0
              end as fatigue_last_7_days,
              FROM(
              select
              date(start_at_local) as start_at_local,
              attention.ad_id,
              fatigue_cutoff_date,
              avg(attention_seconds_true) as average_attention,
              count(*) as datapoints,
              from ${attention_seconds.SQL_TABLE_NAME} attention
              inner join
              (select
               ad_id,
               date_sub(max(date(start_at_utc)), INTERVAL 7 DAY) as fatigue_cutoff_date
               from `data_pipeline.attention_seconds`
               group by
               1
              ) fatigue_lu
              ON attention.ad_id = fatigue_lu.ad_id
              group by
              1,
              2,
              3
              ) fatigue
              inner join ${attention_creative_average.SQL_TABLE_NAME} creative
              on fatigue.ad_id = creative.ad_id
              where
              {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
              {% condition filters.frame_scope_creative_id %} fatigue.ad_id {% endcondition %} AND
              {% condition filters.frame_scope_report_id %} report_code {% endcondition %};;
    }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: ad_id {
    type: string
    sql: ${TABLE}.ad_id ;;
  }

  dimension: creative_average {
    type: number
    sql: ${TABLE}.creative_average ;;
  }

  dimension: fatigue_last_7_days {
    type: number
    sql: ${TABLE}.fatigue_last_7_days ;;
  }

  dimension_group: start_at_local {
    type: time
    sql: ${TABLE}.start_at_local ;;
  }

  measure: average_attention {
    type: average
    sql: ${TABLE}.average_attention ;;
  }

  measure: datapoints {
    type: sum
    sql: ${TABLE}.datapoints ;;
  }

  dimension_group: fatigue_cutoff_date {
    type: time
    sql: ${TABLE}.fatigue_cutoff_date ;;
  }


    set: detail {
      fields: [
      ]
    }
  }

#   }
# }
