
view: report_tracking {
  derived_table: {
    sql: SELECT * FROM `tech-data-warehouse.uploads.vplus_report_tracking` ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: final_report_due_date {
    type: date
    datatype: date
    sql: ${TABLE}.Final_Report_Due_Date ;;
  }

  dimension: opportunity_owner {
    type: string
    sql: ${TABLE}.Opportunity_Owner ;;
  }

  dimension: opportunity_name {
    type: string
    sql: ${TABLE}.Opportunity_Name ;;
  }

  dimension: __of_products {
    type: number
    sql: ${TABLE}.__of_Products ;;
  }

  dimension: start_date__a_ {
    type: date
    datatype: date
    sql: ${TABLE}.Start_Date__A_ ;;
  }

  dimension: end_date__a_ {
    type: date
    datatype: date
    sql: ${TABLE}.End_Date__A_ ;;
  }

  dimension: _contract_amount_ {
    type: string
    sql: ${TABLE}._Contract_Amount_ ;;
  }

  dimension: report_type {
    type: string
    sql: ${TABLE}.Report_Type ;;
  }

  dimension: close_date {
    type: date
    datatype: date
    sql: ${TABLE}.Close_Date ;;
  }

  dimension: campaign_buy_type {
    type: string
    sql: ${TABLE}.Campaign_Buy_Type ;;
  }

  set: detail {
    fields: [
      final_report_due_date,
      opportunity_owner,
      opportunity_name,
      __of_products,
      start_date__a_,
      end_date__a_,
      _contract_amount_,
      report_type,
      close_date,
      campaign_buy_type
    ]
  }
}
