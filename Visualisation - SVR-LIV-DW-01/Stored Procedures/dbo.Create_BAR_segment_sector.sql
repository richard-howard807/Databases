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

SELECT [Actuals].segment,
       [Actuals].sector,
       [Actuals].dim_gl_date_key,
       [Actuals].gl_fin_month_no,
       [Actuals].gl_fin_year,
       [Actuals].gl_fin_period,
       [Actuals].gl_fin_month,
	   [Actuals].gl_calendar_date, 
       [Actuals].bill_amount,
       [Actuals].outstanding_total_bill,
       [Actuals].outstanding_total_bill_180_days,
       [Actuals].outstanding_costs,
       [Actuals].outstanding_costs_180_days,
       [Actuals].wip_minutes,
       [Actuals].wip_value,
       [Actuals].wip_over_90_days,
       fact_segment_target_upload.target_value,
	   anual_target,
       PREVIOUS_DATA.bill_amount AS bill_amount_previous_year_month,
       PREVIOUS_DATA.outstanding_total_bill AS outstanding_total_bill_previous_year_month,
       PREVIOUS_DATA.outstanding_total_bill_180_days AS outstanding_total_bill_180_days_previous_year_month,
       PREVIOUS_DATA.wip_value AS wip_value_previous_year_month,
       PREVIOUS_DATA.wip_over_90_days AS wip_over_90_days_previous_year_month
INTO dbo.BAR_segment_sector
FROM

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
) [Actuals]

	LEFT OUTER JOIN red_dw.[dbo].fact_segment_target_upload 
	ON fact_segment_target_upload.segmentname=[Actuals].segment
	AND fact_segment_target_upload.sectorname=[Actuals].sector
	AND [Actuals].gl_fin_month_no=fact_segment_target_upload.financial_month
	AND [Actuals].gl_fin_year=fact_segment_target_upload.year
	AND [Actuals].gl_fin_year>=2021

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
        ON [Actuals].segment = PREVIOUS_DATA.segment
           AND [Actuals].sector = PREVIOUS_DATA.sector
           AND [Actuals].gl_fin_month_no = PREVIOUS_DATA.gl_fin_month_no
           AND [Actuals].gl_fin_year-1= PREVIOUS_DATA.gl_fin_year;


--select * from [dbo].[BAR_segment_targets]



GO
