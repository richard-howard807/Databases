SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-02-06
-- Description:	decrease time it takes for report to complete 
-- =============================================

CREATE PROCEDURE [dbo].[UTBMS_London_Report]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

;WITH cte as (
SELECT 
dfh.fed_code,
dmh.client_code,
dmh.matter_number,
dmh.dss_current_flag,
dmh.matter_owner_full_name,
dfh.hierarchylevel4hist team,
dmh.dss_end_date,
dmh.ms_only,
CASE WHEN ISNUMERIC(dmh.client_code) = 1 THEN CAST(CAST(client_code AS INT) AS NVARCHAR(8)) ELSE RTRIM(LTRIM(client_code)) END +'-'+ CASE WHEN ISNUMERIC(matter_number) = 1 THEN CAST(CAST(matter_number AS INT) AS NVARCHAR(8)) ELSE RTRIM(LTRIM(matter_number)) END [3e_number],
RTRIM(LTRIM(client_code)) +'-'+  RTRIM(LTRIM(matter_number))  [load_number],
RANK() OVER (PARTITION BY dmh.client_code, dmh.matter_number ORDER BY  dmh.dss_start_date DESC ) AS [rank]
FROM red_dw.dbo.dim_matter_header_history dmh
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history dfh ON dfh.dss_current_flag = 'Y' and dmh.fee_earner_code = dfh.fed_code AND dfh.activeud = 1
WHERE 
dmh.dss_current_flag = 'N' AND 
dmh.matter_number NOT IN ('ML','Unknown','.       ') AND hierarchylevel4hist IS NOT NULL 
)


SELECT 
feeearner.client_code
,feeearner.matter_number
,feeearner.fee_earner_code
,feeearner.matter_owner_full_name
,feeearner.team
,cte.matter_owner_full_name pre_name
,cte.fed_code AS pre_fed_code
,cte.team pre_team
,dss_start_date
,max_date
,md.ptagroup
,amount
,ms_only
FROM red_Dw.dbo.ds_sh_3e_mattdate md
LEFT JOIN red_Dw.dbo.ds_sh_3e_matter m ON  md.matterlkup = m.mattindex

LEFT JOIN 
(
SELECT 
CASE WHEN ISNUMERIC(dmh.client_code) = 1 THEN CAST(CAST(client_code AS INT) AS NVARCHAR(8)) ELSE RTRIM(LTRIM(client_code)) END +'-'+ CASE WHEN ISNUMERIC(matter_number) = 1 THEN CAST(CAST(matter_number AS INT) AS NVARCHAR(8)) ELSE RTRIM(LTRIM(matter_number)) END [3e_number],
RTRIM(LTRIM(client_code)) +'-'+  RTRIM(LTRIM(matter_number))  [load_number],
client_code,
matter_number,
fee_earner_code,
dmh.matter_owner_full_name,
dfh.hierarchylevel4hist team,
dfh.name,
dmh.dss_start_date,
ms_only
FROM red_dw.dbo.dim_matter_header_history dmh
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history dfh ON dfh.dss_current_flag = 'Y' and dmh.fee_earner_code = dfh.fed_code 
WHERE dmh.dss_current_flag = 'Y' AND dmh.matter_number NOT IN ('ML','Unknown','.       ') AND hierarchylevel4hist IS NOT NULL
) feeearner ON feeearner.[3e_number] = m.number 
inner JOIN (
		SELECT	
				cte.client_code,
				cte.matter_number,
				matter_owner_full_name,
				team,
				cte.fed_code, 
				MAX(dss_end_date) AS max_date 
			FROM cte 
			WHERE cte.rank = 1 
			GROUP BY 
				cte.client_code,
				cte.matter_number,
				matter_owner_full_name,
				team,
				cte.fed_code 
			)   cte ON cte.client_code = feeearner.client_code AND feeearner.matter_number = cte.matter_number
LEFT JOIN (SELECT  
client,
matter,
SUM(wip_value) amount
FROM red_Dw.dbo.fact_wip_daily 
WHERE CAST(wip_date AS DATE) = '2016-07-20'
AND wip_value <> 0
GROUP BY  client,
matter
) wip ON wip.client = feeearner.client_code AND wip.matter = feeearner.matter_number
WHERE 
(feeearner.team = 'Litigation London' OR cte.team = 'Litigation London')
--AND m.number = '113147-310' 
AND md.nxenddate = '9999-12-31 00:00:00.000'
AND not EXISTS ( SELECT * FROM cte WHERE cte.client_code = feeearner.client_code AND feeearner.matter_number = cte.matter_number AND cte.fed_code = feeearner.fee_earner_code)
--AND cte.fed_code IS NOT null and 
AND dss_start_date > '2018-01-15'


END
GO
