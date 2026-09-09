view: flight_date_range_clipping_helper_v {
  #
  # This view helps with filtering other views by a set of flight
  # start-end date ranges. The intent is to use this view to constrain
  # other views via an inner join to limit to data that falls within
  # the duration of each flight.
  #
  # Example:
  #  Given a set of flight ids, say 7 and 8 where flight 7 runs in
  #  the first week of 2022 and flight 8 runs in the third week (made
  #  up for example), the output from this view may look something
  #  like the following (note the discontinuous jump):
  #
  #  2022-01-02
  #  2022-01-03
  #  2022-01-04
  #  2022-01-05
  #  2022-01-06
  #  2022-01-07
  #  2022-01-16
  #  2022-01-17
  #  2022-01-18
  #  2022-01-19
  #  2022-01-20
  #  2022-01-21
  #  2022-01-22
  #
  #  Importantly, we ensure that each date in the result is unique (no
  #  duplication) so that no duplication occurs when this output is
  #  used in join statements.
  #
  derived_table: {
    sql: (
      with
        flight_date_ranges as (
          select
            CAST(campaign_id as numeric) as flight_id,
            DATE(start_at) as start_date,
            DATE(end_at) as end_date
        from ${creatives.SQL_TABLE_NAME}
        where
      --{% condition filters.frame_scope_flight_id %} id {% endcondition %}
        {% condition filters.frame_scope_campaign_id %} campaign_id {% endcondition %} AND
        {% condition filters.frame_scope_creative_id %} ad_id {% endcondition %} AND
        {% condition filters.frame_scope_report_id %} report_code {% endcondition %} AND
        {% condition filters.frame_scope_campaign_group %} campaign_group {% endcondition %} AND
        {% condition filters.frame_scope_creative_group %} creative_group {% endcondition %} AND
        {% condition filters.frame_scope_creative_group2 %} creative_group2 {% endcondition %}
        ),
          flight_date_arrays as (
          select
            generate_date_array(start_date, end_date, interval 1 day) as date_arrays
          from
            flight_date_ranges
        )
      select
        distinct dates
      from
        flight_date_arrays, UNNEST(date_arrays) as dates
    );;
  }

  measure: count_test_helper {
    hidden:  yes
    type: count
  }

  dimension: dates {
    type: date
    datatype: date
    sql: ${TABLE}.dates ;;
  }
}
