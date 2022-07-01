CREATE TABLE charter_20222506_file_data AS (
  SELECT * FROM charter_file_data
);

TRUNCATE TABLE charter_file_data;

-- \copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220107_details.txt.csv' DELIMITER ',' CSV HEADER
-- \copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220506_details_since_2022_12_27.txt.csv' DELIMITER ',' CSV HEADER
-- \copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220505_details_since_2022_12_27.txt.csv' DELIMITER ',' CSV HEADER
-- \copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220427_details_2021_12_27_forward.txt.csv' DELIMITER ',' CSV HEADER
-- \copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220331_details_2021_12_27_forward.txt.csv' DELIMITER ',' CSV HEADER
\copy charter_file_data FROM 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220521_details.txt.csv' DELIMITER ',' CSV HEADER

REFRESH MATERIALIZED VIEW annotated_data;
REFRESH MATERIALIZED VIEW annotated_vantage_data;

---------------------------------------------------------

CREATE MATERIALIZED VIEW annotated_data AS
WITH aggregate AS (
  SELECT
    "Audience Segment Name",
    "Event Date",
    "Event Time",
    "Network",
    "Impressions Delivered",
    "ISCI/ADID",
    COUNT(*) OVER should_be_unique AS num_rows,
    STDDEV("Impressions Delivered") OVER should_be_unique AS imps_dev
  FROM charter_file_data
  WHERE "Audience Segment Name" != 'Default'
  WINDOW should_be_unique AS (PARTITION BY "Audience Segment Name", "Event Date", "Event Time", "Network")
),

aggregate_with_isci_count AS (
  SELECT
    "Audience Segment Name",
    "Event Date",
    "Event Time",
    "Network",
    COUNT(DISTINCT "ISCI/ADID") AS num_iscis
  FROM aggregate
  GROUP BY "Audience Segment Name", "Event Date", "Event Time", "Network"
)

-- SELECT *
-- FROM aggregate_with_isci_count
-- WHERE num_iscis > 1

-- SELECT *
-- FROM aggregate
-- -- WHERE imps_dev > 0
-- WHERE num_rows > 1
--   AND "Audience Segment Name" != 'Default'
--   AND "Audience Segment Name" LIKE 'O%'

-- SELECT *
-- FROM aggregate_with_isci_count wisci
--   NATURAL INNER JOIN aggregate
-- WHERE wisci.num_iscis > 1

SELECT
  "Audience Segment Name",
  "Event Date",
  "Event Time",
  "Network",
  "Impressions Delivered",
  "ISCI/ADID",
  num_rows,
  num_iscis,
  imps_dev = 0 AS impressions_duplicated
FROM aggregate_with_isci_count
  NATURAL INNER JOIN aggregate
;

CREATE MATERIALIZED VIEW annotated_vantage_data
AS SELECT * FROM annotated_data
WHERE "Audience Segment Name" LIKE '%\_VA\_%'
;

CREATE OR REPLACE VIEW unexpected_duplicate_vantage_rows
AS SELECT * FROM annotated_vantage_data
WHERE num_rows > num_iscis
ORDER BY "Audience Segment Name", "Event Date", "Event Time", "Network", "ISCI/ADID";

CREATE OR REPLACE VIEW vantage_segments_with_multiple_iscis AS
WITH iscis_by_segment AS (
  SELECT
    "Audience Segment Name",
    array_agg(DISTINCT "ISCI/ADID") as iscis
  FROM annotated_vantage_data
  GROUP BY "Audience Segment Name"
),

segments_with_multiple_iscis AS (
  SELECT "Audience Segment Name"
  FROM iscis_by_segment
  WHERE CARDINALITY(iscis) > 1
)

SELECT
  "Audience Segment Name",
  "ISCI/ADID",
  SUM("Impressions Delivered") AS total_impressions
FROM annotated_vantage_data
WHERE "Audience Segment Name" IN (SELECT * FROM segments_with_multiple_iscis)
GROUP BY "Audience Segment Name", "ISCI/ADID"
ORDER BY "Audience Segment Name", "ISCI/ADID"
;


---------------------------------------------------------
--- What's up with these weird ISCIs?
WITH segments_by_isci AS (
  SELECT
    "ISCI/ADID",
    array_agg(DISTINCT "Audience Segment Name") as segments
  FROM charter_file_data
  WHERE "Audience Segment Name" LIKE '%\_VA\_%'
  GROUP BY "ISCI/ADID"
),

iscis_with_multiple_segments AS (
  SELECT "ISCI/ADID"
  FROM segments_by_isci
  WHERE CARDINALITY(segments) > 1
)

SELECT
  "ISCI/ADID",
  "Audience Segment Name",
  SUM("Impressions Delivered") AS total_impressions
FROM charter_file_data
WHERE "ISCI/ADID" IN (SELECT * FROM iscis_with_multiple_segments)
GROUP BY "Audience Segment Name", "ISCI/ADID"
ORDER BY "Audience Segment Name", "ISCI/ADID"
;

---------------------------------------------------------
--- As above, but finding segments with multiple ISCIs
WITH iscis_by_segment AS (
  SELECT
    "Audience Segment Name",
    array_agg(DISTINCT "ISCI/ADID") as iscis
  FROM charter_file_data
  WHERE "Audience Segment Name" LIKE '%\_VA\_%'
  GROUP BY "Audience Segment Name"
),

segments_with_multiple_iscis AS (
  SELECT "Audience Segment Name"
  FROM iscis_by_segment
  WHERE CARDINALITY(iscis) > 1
)

SELECT
  "Audience Segment Name",
  "ISCI/ADID",
  SUM("Impressions Delivered") AS total_impressions
FROM charter_file_data
WHERE "Audience Segment Name" IN (SELECT * FROM segments_with_multiple_iscis)
GROUP BY "Audience Segment Name", "ISCI/ADID"
ORDER BY "Audience Segment Name", "ISCI/ADID"
;

---------------------------------------------------------
--- What changed in the latest file?
CREATE TABLE file_comparison AS (
  SELECT
    "Audience Segment Name",
    "Event Date",
    "Event Time",
    "Network",
    "ISCI/ADID",
    prev."Advertiser" AS prev_advertiser,
    cur."Advertiser" AS cur_advertiser,
    prev."Campaign Name" AS prev_campaign_name,
    cur."Campaign Name" AS cur_campaign_name,
    prev."Campaign Start Date" AS prev_campaign_start_date,
    cur."Campaign Start Date" AS cur_campaign_start_date,
    "Campaign End Date" DATE,
  FROM
    charter_file_data cur
    FULL OUTER JOIN
      charter_20220423_file_data prev
      USING ("Audience Segment Name", "Event Date", "Event Time", "Network", "ISCI/ADID")
)
;
