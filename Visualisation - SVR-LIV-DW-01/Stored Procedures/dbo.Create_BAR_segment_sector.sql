SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--SELECT * FROM dbo.BAR_segment_sector WHERE segment='Misc'
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Create_BAR_segment_sector]
AS
DROP TABLE IF EXISTS dbo.BAR_segment_sector;

SELECT fact_segment_target_upload.segmentname segment,
       fact_segment_target_upload.sectorname sector,
       CURRENT_DATA.dim_gl_date_key,
       fact_segment_target_upload.financial_month gl_fin_month_no,
       fact_segment_target_upload.year gl_fin_year,
       fact_segment_target_upload.fin_period gl_fin_period,
       CURRENT_DATA.gl_fin_month,
	   CAST(CAST(fact_segment_target_upload.year AS NVARCHAR(4))+'-'+fact_segment_target_upload.month+'-01 00:00:00.000' AS DATETIME2) gl_calendar_date,
       CURRENT_DATA.bill_amount,
       CURRENT_DATA.outstanding_total_bill,
       CURRENT_DATA.outstanding_total_bill_180_days,
       CURRENT_DATA.outstanding_costs,
       CURRENT_DATA.outstanding_costs_180_days,
       CURRENT_DATA.wip_minutes,
       CURRENT_DATA.wip_value,
       CURRENT_DATA.wip_over_90_days,
       fact_segment_target_upload.target_value,
	   anual_target,
       PREVIOUS_DATA.bill_amount AS bill_amount_previous_year_month,
       PREVIOUS_DATA.outstanding_total_bill AS outstanding_total_bill_previous_year_month,
       PREVIOUS_DATA.outstanding_total_bill_180_days AS outstanding_total_bill_180_days_previous_year_month,
       PREVIOUS_DATA.wip_value AS wip_value_previous_year_month,
       PREVIOUS_DATA.wip_over_90_days AS wip_over_90_days_previous_year_month
INTO dbo.BAR_segment_sector
FROM

  red_dw.[dbo].fact_segment_target_upload
LEFT JOIN        
(
    SELECT CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE segment end segment,
           CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE sector end sector,
           fact_agg_client_monthly_rollup.dim_gl_date_key,
           gl_fin_month_no,
           gl_fin_year,
           gl_fin_period,
           gl_fin_month,
           gl_calendar_date,
           SUM(bill_amount) bill_amount,
           SUM(outstanding_total_bill) outstanding_total_bill,
           SUM(outstanding_total_bill_180_days) outstanding_total_bill_180_days,
           SUM(outstanding_costs) outstanding_costs,
           SUM(outstanding_costs_180_days) outstanding_costs_180_days,
           SUM(wip_minutes) wip_minutes,
           SUM(wip_value) wip_value,
           SUM(wip_over_90_days) wip_over_90_days
    FROM red_dw.dbo.fact_agg_client_monthly_rollup
        INNER JOIN red_dw.dbo.dim_client
            ON dim_client.dim_client_key = fact_agg_client_monthly_rollup.dim_client_key
        INNER JOIN red_dw.dbo.dim_gl_date
            ON dim_gl_date.dim_gl_date_key = fact_agg_client_monthly_rollup.dim_gl_date_key
    WHERE fact_agg_client_monthly_rollup.dim_gl_date_key >=
    (
        SELECT dim_date_key
        FROM red_dw.dbo.dim_date
        WHERE fin_year =
        (
            SELECT fin_year - 2
            FROM red_dw.dbo.dim_date
            WHERE calendar_date = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
        )
              AND fin_day_in_year = 1
    )
    GROUP BY CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE segment end,
           CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE sector end,
             fact_agg_client_monthly_rollup.dim_gl_date_key,
             gl_fin_month_no,
             gl_fin_year,
             gl_fin_period,
             gl_fin_month,
             gl_calendar_date
) CURRENT_DATA
 ON CURRENT_DATA.gl_fin_year = fact_segment_target_upload.year
           AND 
		   CURRENT_DATA.segment = fact_segment_target_upload.segmentname COLLATE DATABASE_DEFAULT
		    AND CURRENT_DATA.sector = fact_segment_target_upload.sectorname COLLATE DATABASE_DEFAULT
			
			AND CURRENT_DATA.gl_fin_month_no=fact_segment_target_upload.financial_month


	LEFT JOIN (select sum(target_value) anual_target,segmentname,sectorname,year from red_dw.[dbo].fact_segment_target_upload
	GROUP BY segmentname,sectorname,year) anual_target 
        ON fact_segment_target_upload.year = anual_target.year
           AND fact_segment_target_upload.segmentname = anual_target.segmentname COLLATE DATABASE_DEFAULT
		    AND fact_segment_target_upload.sectorname = anual_target.sectorname COLLATE DATABASE_DEFAULT

    LEFT JOIN
    (
        SELECT CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE segment end segment,
           CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE sector end sector,
               fact_agg_client_monthly_rollup.dim_gl_date_key,
               gl_fin_month_no,
               gl_fin_year,
               gl_fin_period,
               gl_fin_month,
               gl_calendar_date,
               SUM(bill_amount) bill_amount,
               SUM(outstanding_total_bill) outstanding_total_bill,
               SUM(outstanding_total_bill_180_days) outstanding_total_bill_180_days,
               SUM(outstanding_costs) outstanding_costs,
               SUM(outstanding_costs_180_days) outstanding_costs_180_days,
               SUM(wip_minutes) wip_minutes,
               SUM(wip_value) wip_value,
               SUM(wip_over_90_days) wip_over_90_days
        FROM red_dw.dbo.fact_agg_client_monthly_rollup
            INNER JOIN red_dw.dbo.dim_client
                ON dim_client.dim_client_key = fact_agg_client_monthly_rollup.dim_client_key
            INNER JOIN red_dw.dbo.dim_gl_date
                ON dim_gl_date.dim_gl_date_key = fact_agg_client_monthly_rollup.dim_gl_date_key
        WHERE fact_agg_client_monthly_rollup.dim_gl_date_key >=
        (
            SELECT dim_date_key
            FROM red_dw.dbo.dim_date
            WHERE fin_year =
            (
                SELECT fin_year - 3
                FROM red_dw.dbo.dim_date
                WHERE calendar_date = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
            )
                  AND fin_day_in_year = 1
        )
        GROUP BY CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE segment end,
				CASE WHEN segment IS NULL OR sector IS NULL THEN 'Misc'ELSE sector end,
                 fact_agg_client_monthly_rollup.dim_gl_date_key,
                 gl_fin_month_no,
                 gl_fin_year,
                 gl_fin_period,
                 gl_fin_month,
                 gl_calendar_date
    ) PREVIOUS_DATA
        ON fact_segment_target_upload.segmentname = PREVIOUS_DATA.segment
           AND fact_segment_target_upload.sectorname = PREVIOUS_DATA.sector
           AND fact_segment_target_upload.financial_month = PREVIOUS_DATA.gl_fin_month_no
           AND fact_segment_target_upload.year-1= PREVIOUS_DATA.gl_fin_year;


--select * from [dbo].[BAR_segment_targets]

--truncate table [dbo].[BAR_segment_targets]

--insert into [dbo].[BAR_segment_targets]

--values
--(2019,'Built environment', 1.1265)
--,(2019,'Corporates' , 1.159)
--,(2019, 'Insurance' , 1.04)
--,(2019, 'OMB' , 1.14)
--,(2019, 'Private client' , 1.035)
--,(2019, 'Public bodies' , 1.091)
--,(2018,'Built environment', 0)
--,(2018,'Corporates' , 0)
--,(2018, 'Insurance' , 0)
--,(2018, 'OMB' ,0)
--,(2018, 'Private client' , 0)
--,(2018, 'Public bodies' , 0)


GO
