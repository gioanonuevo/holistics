
view: campaign_by_properties {
  derived_table: {
    sql: select
      property_id,
      properties.name,
      count(campaign_id) as direct_campaigns,
      sum(loop_spots) as direct_campaign_loop_spots
      from `raw_elev8_backend.raw_campaign_locations` loc
      left join `raw_elev8_backend.raw_campaigns` campaigns
      on loc.campaign_id = campaigns.id
      left join `raw_elev8_backend.raw_properties` properties
      on loc.property_id = properties.id
      where
      loc.__hevo__marked_deleted = FALSE and
      campaigns.__hevo__marked_deleted = FALSE and
      campaigns.status = 'active' and
      CURRENT_DATE() between date(start_at) and date(end_at)
      group by 1,2 ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: property_id {
    type: number
    sql: ${TABLE}.property_id ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: direct_campaigns {
    type: number
    sql: ${TABLE}.direct_campaigns ;;
  }

  dimension: direct_campaign_loop_spots {
    type: number
    sql: ${TABLE}.direct_campaign_loop_spots ;;
  }

  set: detail {
    fields: [
      property_id,
      name,
      direct_campaigns,
      direct_campaign_loop_spots
    ]
  }
}
