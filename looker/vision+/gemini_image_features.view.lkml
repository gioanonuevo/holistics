
view: gemini_image_features {
  derived_table: {
    sql: SELECT id,a.* FROM `tech-data-warehouse.uploads.gemini_image_analysis`  a
      left join `raw_elev8_backend.raw_ads` b
      on replace(replace(a.file_name,'.jpg',''),'.png','') = b.title ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: id {
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: file_name {
    type: string
    sql: ${TABLE}.file_name ;;
  }

  dimension: predominant_brand {
    type: string
    sql: ${TABLE}.predominant_brand ;;
  }

  dimension: product {
    type: string
    sql: ${TABLE}.product ;;
  }

  dimension: industry_category {
    type: string
    sql: ${TABLE}.industry_category ;;
  }

  dimension: primary_goal {
    type: string
    sql: ${TABLE}.primary_goal ;;
  }

  dimension: call_to_action {
    type: string
    sql: ${TABLE}.call_to_action ;;
  }

  dimension: total_word_count {
    type: number
    sql: ${TABLE}.total_word_count ;;
  }

  dimension: headline_word_count {
    type: number
    sql: ${TABLE}.headline_word_count ;;
  }

  dimension: body_word_count {
    type: number
    sql: ${TABLE}.body_word_count ;;
  }

  dimension: dominant_colors {
    type: string
    sql: ${TABLE}.dominant_colors ;;
  }

  dimension: emotional_tone {
    type: string
    sql: ${TABLE}.emotional_tone ;;
  }

  dimension: offer_associated {
    type: yesno
    sql: ${TABLE}.offer_associated ;;
  }

  dimension: qr_code_presence {
    type: yesno
    sql: ${TABLE}.qr_code_presence ;;
  }

  dimension: man_presence {
    type: yesno
    sql: ${TABLE}.man_presence ;;
  }

  dimension: woman_presence {
    type: yesno
    sql: ${TABLE}.woman_presence ;;
  }

  dimension: family_couple_presence {
    type: yesno
    sql: ${TABLE}.family_couple_presence ;;
  }

  dimension: animal_presence {
    type: yesno
    sql: ${TABLE}.animal_presence ;;
  }

  dimension: advertisement_summary {
    type: string
    sql: ${TABLE}.advertisement_summary ;;
  }

  set: detail {
    fields: [
      id,
      file_name,
      predominant_brand,
      product,
      industry_category,
      primary_goal,
      call_to_action,
      total_word_count,
      headline_word_count,
      body_word_count,
      dominant_colors,
      emotional_tone,
      offer_associated,
      qr_code_presence,
      man_presence,
      woman_presence,
      family_couple_presence,
      animal_presence,
      advertisement_summary
    ]
  }
}
