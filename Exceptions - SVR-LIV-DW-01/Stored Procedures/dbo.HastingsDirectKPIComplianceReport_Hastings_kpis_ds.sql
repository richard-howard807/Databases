SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[HastingsDirectKPIComplianceReport_Hastings_kpis_ds]

AS

SELECT 
	kpi_unpivot.[Supplier Reference]
	, CASE	
		WHEN CAST(kpi_unpivot.kpis AS INT) = 10 THEN
			'KPI A.1 Fundamental Dishonesty - Pleaded'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 20 THEN
			'KPI A.1 Fundamental Dishonesty Success - Withdrawn'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 30 THEN
			'KPI A.1 Fundamental Dishonesty Success - Compromised'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 40 THEN
			'KPI A.1 Fundamental Dishonesty Success - Failed'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 50 THEN
			'KPI A.2 Contribution Proceedings'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 60 THEN
			'KPI A.3 Indemnity Recoveries'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 70 THEN
			'KPI A.4 Offers and Outcomes'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 80 THEN
			'KPI A.5 Lifecycle'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 90 THEN
			'KPI A.6 Internal Monthly Audits'
	  END				AS kpi_name
	, CASE	
		WHEN CAST(kpi_unpivot.kpis AS INT) = 10 THEN
			'Once the Supplier has identified realistic prospects of fundamental dishonesty, at least 50% of these to result in fundamental dishonesty being pleaded.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 20 THEN
			'When fundamental dishonesty is pleaded at least 70% to result in the claimant withdrawing their claim.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 30 THEN
			'When fundamental dishonesty is pleaded at least 20% to result in compromising their claim.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 40 THEN
			'When fundamental dishonesty is pleaded at least 10% of these claims failing entirely.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 50 THEN
			'When a party is brought into proceedings, a recovery of £1 or more to be achieved 90% of the time.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 60 THEN
			'Where indemnity is compromised, the Supplier to investigate the prospect of recovery immediately. Where prospect is identified as above, a recovery is achieved 5% of the time.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 70 THEN
			'True (not tactical) Part 36/Calderbank/other offers made with the intention to rely on at trial. At trial, to be successful at least 70% of the time.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 80 THEN
			'The target settlement date to be met or bettered on at least 85% of Claims.'
		WHEN CAST(kpi_unpivot.kpis AS INT) = 90 THEN
			'Supplier’s internal monthly audit results; to achieve 90% pass rate.'
	  END				AS kpi_description
	, CAST(kpi_unpivot.kpis AS INT)		AS row_order
	, CASE 
		WHEN CAST(kpi_unpivot.kpis AS INT) = 10 THEN
			0.5
		WHEN CAST(kpi_unpivot.kpis AS INT) IN (20, 70) THEN
			0.7
		WHEN CAST(kpi_unpivot.kpis AS INT) = 30 THEN
			0.2
		WHEN CAST(kpi_unpivot.kpis AS INT) = 40 THEN
			0.1
		WHEN CAST(kpi_unpivot.kpis AS INT) = 50 THEN
			0.9
		WHEN CAST(kpi_unpivot.kpis AS INT) = 60 THEN
			0.05
		WHEN CAST(kpi_unpivot.kpis AS INT) = 80 THEN
			0.85
		WHEN CAST(kpi_unpivot.kpis AS INT) = 90 THEN
			0.95
	  END					AS kpi_target
	, kpi_unpivot.kpi_result
	, IIF(ISNULL(kpi_unpivot.kpi_result, 'TBC') <> 'TBC', 1, NULL)		AS total_count
	, IIF(kpi_unpivot.kpi_result = 'N/A', 1, NULL)		AS [KPI N/A - Number of Matters]
	, IIF(kpi_unpivot.kpi_result = 'Achieved', 1, NULL)		AS [KPI Achieved - Number of Matters]
	, IIF(kpi_unpivot.kpi_result = 'Not Achieved', 1, NULL)		AS [KPI Not Achieved - Number of Matters]
FROM (
		SELECT 
            hastings_listing_table.[Supplier Reference],
            hastings_listing_table.[KPI A.2 Fundamental Dishonesty Pleaded]	AS [10],
            hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Withdrawn] AS [20],
            hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Compromised] AS [30],
            hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Failed] AS [40],
            hastings_listing_table.[KPI A.2 Contribution Proceedings] AS [50],
            hastings_listing_table.[KPI A.3 Indemnity Recoveries] AS [60],
            hastings_listing_table.[KPI A.4 Offers and Outcomes] AS [70],
            hastings_listing_table.[KPI A.5 Lifecycle] AS [80],
            hastings_listing_table.[KPI A.7 Internal Monthly Audits] AS [90]
		FROM Reporting.dbo.hastings_listing_table

		WHERE TRIM(ISNULL(hastings_listing_table.[Referral Reason - DELETE BEFORE SENDING],'')) <> 'Advice only'
	) AS kpis
UNPIVOT (
		kpi_result
		FOR kpis IN ([10], [20], [30], [40], [50], [60], [70], [80], [90])
	) AS kpi_unpivot

GO
