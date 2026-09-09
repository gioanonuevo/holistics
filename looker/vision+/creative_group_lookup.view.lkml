
view: creative_group_lookup {
  derived_table: {
    sql: SELECT * FROM `data_pipeline.stg_client_dashboard_creative_groups_lu` ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: creative_id {
    type: string
    sql: ${TABLE}.creative_id ;;
  }

  dimension: creative_group {
    type: string
    sql: ${TABLE}.creative_group ;;
  }

  dimension: creative_group2 {
    type: string
    sql: ${TABLE}.creative_group2 ;;
  }

  set: detail {
    fields: [
      creative_id,
      creative_group,
      creative_group2
    ]
  }
}
