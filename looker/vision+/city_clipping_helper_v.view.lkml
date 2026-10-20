
view: city_clipping_helper_v {
  derived_table: {
    sql: WITH detection_demography AS (select
            *
            FROM
            `tech-data-warehouse.data_pipeline.detection_demography`
            where age_group not in ('18 below','no info') )
        ,  attention_seconds AS (SELECT
            attention.*,
            demo.gender,
            demo.gender_pie,
            demo.age_group,
            demo.generation,
            demo.gender_v2,
            case
            when attention_seconds_true >= 2.5 then 'Message Exposure'
            when attention_seconds_true < 2.5 then 'Brand Exposure'
            else ''
            end as exposure_category,
            campaigns.report_code,
            CASE
          -- Atlantic Time (Includes DST)
          WHEN address_province IN ('NS', 'NB', 'PE', 'Nova Scotia', 'New Brunswick', 'Prince Edward Island')
              THEN DATETIME(start_at_utc, 'America/Halifax')
          -- Newfoundland Time (Handles the unique 30-min offset + DST)
          WHEN address_province IN ('NL', 'Newfoundland and Labrador')
              THEN DATETIME(start_at_utc, 'America/St_Johns')
          -- Eastern Time (Toronto/Montreal)
          WHEN address_province IN ('ON', 'QC', 'Ontario', 'Quebec')
              THEN DATETIME(start_at_utc, 'America/Toronto')
          -- Central Time (Winnipeg)
          WHEN address_province IN ('MB', 'Manitoba')
              THEN DATETIME(start_at_utc, 'America/Winnipeg')
          -- Saskatchewan (Correctly stays on CST year-round)
          WHEN address_province IN ('SK', 'Saskatchewan')
              THEN DATETIME(start_at_utc, 'America/Regina')
          -- Mountain Time (Edmonton/Calgary)
          WHEN address_province IN ('AB', 'NT', 'Alberta', 'Northwest Territories')
              THEN DATETIME(start_at_utc, 'America/Edmonton')
          -- Pacific Time (Vancouver)
          WHEN address_province IN ('BC', 'YT', 'British Columbia', 'Yukon')
              THEN DATETIME(start_at_utc, 'America/Vancouver')
          ELSE DATETIME(start_at_utc, 'UTC')
            END as start_at_local,
            attention.ad_length as ad_length,
            case
            when ad_length between 5 and 7 then 5
            when ad_length between 8 and 12 then 10
            when ad_length between 13 and 16 then 15
            when ad_length between 17 and 22 then 20
            when ad_length between 28 and 32 then 30
            else ad_length
            end as ad_length_grouped,
            case
            when attention_seconds_true >= 1 then '>=1'
            when attention_seconds_true < 1 then '<1'
            else ''
            end as atleast_1_sec,
            case
            when attention_seconds_true >= 1.5 then '>=1.5'
            when attention_seconds_true < 1.5 then '<1.5'
            else ''
            end as atleast_1_5_sec,
            case
            when attention_seconds_true >= 2 then '>=2'
            when attention_seconds_true < 2 then '<2'
            else ''
            end as atleast_2_sec,
            ads_type,
            FROM
            `tech-data-warehouse.data_pipeline.attention_seconds` attention
            INNER JOIN
            detection_demography demo
            ON attention.uuid = demo.uuid
            LEFT JOIN
           `tech-data-warehouse.data_pipeline.raw_campaigns` campaigns
            ON attention.campaign_id = cast(campaigns.id as string)
            LEFT JOIN
            (
          select
          property_number as id,
          name,
          case
          when region = 'Alberta' then 'AB'
          when region = 'British Columbia' then 'BC'
          when region = 'Newfoundland and Labrador' then 'NL'
          when region = 'Ontario' then 'ON'
          when region = 'Québec' then 'QC'
          when region = 'Manitoba' then 'MB'
          when region = 'Saskatchewan'then 'SK'
          when region = 'Nova Scotia' then 'NS'
          when region = 'Northwest Territories' then 'NT'
          when region = 'Yukon' then 'YT'
          else region end as address_province,
          case
          when city = 'Calgary' then 'CGY'
          when city = 'Edmonton' then 'EDM'
          when region = 'British Columbia' then 'BC'
          when region = 'Newfoundland and Labrador' then 'NL'
          when region = 'Ontario' then 'ON'
          when region = 'Québec' then 'QC'
          when region = 'Manitoba' then 'MB'
          when region = 'Saskatchewan'then 'SK'
          when region = 'Nova Scotia' then 'NS'
          when region = 'Northwest Territories' then 'NT'
          when region = 'Yukon' then 'YT'
          else region end as address_province2,
          city as address_city,
          string_field_1 as property_type,
          no_of_floors as floors,
          country as address_country,
          SUBSTR(postal_code,0,3) as FSA,
          latitude,
          longitude,
          from `data_pipeline.views_properties_query_results`
          left join
          `uploads.iab_lookup_canada`
          ON string_field_0 = property_type
          where
          country = 'Canada'
          and test = false
          and is_deleted = false
          and status_text = 'ready'
          )  properties
            ON attention.property_id = properties.id
            LEFT JOIN (
            select
            distinct
            ad_id,
            content_type as ads_type from `data_pipeline.stg_campaigns`
            where content_type is not null
            ) content_type
            ON attention.ad_id = content_type.ad_id
            WHERE attention.ad_id IS NOT NULL and attention_seconds_true is NOT NULL AND
      {% condition filters.frame_scope_campaign_id %} attention.campaign_id {% endcondition %} AND
      {% condition filters.frame_scope_creative_id %} attention.ad_id {% endcondition %} AND
      {% condition filters.frame_scope_report_id %} campaigns.report_code {% endcondition %}

      )
        ,  screens_info AS (select
          *,
          1 as screen_installation_config_id,
          1 as index,
          from `tech-data-warehouse.data_pipeline.screen_mac_address_lookup_v2` )
      SELECT
          DISTINCT properties.address_city  AS properties_city
      FROM attention_seconds
      INNER JOIN screens_info ON attention_seconds.device_id = screens_info.mac_address
      INNER JOIN (
          select
          property_number as id,
          name,
          case
          when region = 'Alberta' then 'AB'
          when region = 'British Columbia' then 'BC'
          when region = 'Newfoundland and Labrador' then 'NL'
          when region = 'Ontario' then 'ON'
          when region = 'Québec' then 'QC'
          when region = 'Manitoba' then 'MB'
          when region = 'Saskatchewan'then 'SK'
          when region = 'Nova Scotia' then 'NS'
          when region = 'Northwest Territories' then 'NT'
          when region = 'Yukon' then 'YT'
          else region end as address_province,
          case
          when city = 'Calgary' then 'CGY'
          when city = 'Edmonton' then 'EDM'
          when region = 'British Columbia' then 'BC'
          when region = 'Newfoundland and Labrador' then 'NL'
          when region = 'Ontario' then 'ON'
          when region = 'Québec' then 'QC'
          when region = 'Manitoba' then 'MB'
          when region = 'Saskatchewan'then 'SK'
          when region = 'Nova Scotia' then 'NS'
          when region = 'Northwest Territories' then 'NT'
          when region = 'Yukon' then 'YT'
          else region end as address_province2,
          city as address_city,
          string_field_1 as property_type,
          no_of_floors as floors,
          country as address_country,
          SUBSTR(postal_code,0,3) as FSA,
          latitude,
          longitude,
          from `data_pipeline.views_properties_query_results`
          left join
          `uploads.iab_lookup_canada`
          ON string_field_0 = property_type
          where
          country = 'Canada'
          and test = false
          and is_deleted = false
          and status_text = 'ready'
          )  AS properties ON screens_info.property_id = properties.id
      GROUP BY
          1
      ORDER BY
          1
      LIMIT 500 ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: properties_city {
    type: string
    sql: ${TABLE}.properties_city ;;
  }

  set: detail {
    fields: [
      properties_city
    ]
  }
}
