SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 2022-03-24
-- Description:	#138368 Limitation expiry dates - list of dates which are going to expire within the next 12, 6 and 21 days time 
-- =============================================

CREATE PROCEDURE [dbo].[LimitationContributionExpiryDates]

AS
BEGIN
SET NOCOUNT ON;

SELECT
dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MatterSphere Client/Matter Number]
, dim_key_dates.dim_matter_header_curr_key
, dim_key_dates.description
, dim_key_dates.key_date
, dim_key_dates.days_to_key_date
, ROW_NUMBER() OVER(PARTITION BY dim_key_dates.dim_matter_header_curr_key ORDER BY dim_key_dates.key_date)	AS rw
,CASE WHEN UPPER(outcome_of_case) LIKE '%DISCON%' OR UPPER(outcome_of_case) LIKE '%WON%' OR UPPER(outcome_of_case) LIKE '%STRUC%' THEN 'Yes' ELSE 'No' END AS Repudiated
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_worktype.work_type_name AS [Matter Type]
, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
, dim_detail_core_details.present_position AS [Present Position]
, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
,outcome_of_case
,outcome
,date_opened_case_management
,date_closed_case_management
,hierarchylevel3hist AS Department
,hierarchylevel4hist AS Team
--, CASE WHEN DATEADD(YEAR, 1, dim_key_dates.key_date)<GETDATE() THEN 1 ELSE 0 END AS [Expired Recoveries]
--,DATEADD(YEAR, 1, dim_key_dates.key_date)
--, CASE WHEN DATEADD(YEAR, 1, dim_key_dates.key_date)>GETDATE() AND DATEDIFF(MONTH, GETDATE(), DATEADD(YEAR, 1, dim_key_dates.key_date))<=12 THEN 12 ELSE 0 END AS [Limitations Due Within 12 Months]
--,DATEADD(MONTH,12,dim_key_dates.key_date) AS [12 months from KeyDate]
		  --,DATEADD(YEAR, 1, dim_key_dates.key_date)	AS [DATEADD]   -- adds a year on to the key date ('LIMITATION')
--,CASE WHEN DATEDIFF(DAY, GETDATE(), DATEADD(YEAR, 1, dim_key_dates.key_date)) BETWEEN 0 AND 21 THEN 21
--	  WHEN DATEDIFF(DAY, GETDATE(), DATEADD(YEAR, 1, dim_key_dates.key_date)) BETWEEN 22 AND 183 THEN 6
--WHEN DATEDIFF(DAY, GETDATE(), DATEADD(YEAR, 1, dim_key_dates.key_date)) BETWEEN 184 AND 365 THEN 12
--ELSE 0
--END 
--AS [No of days between today and SLA (DATEDIFF)]
,CASE WHEN DATEDIFF(DAY, GETDATE(), dim_key_dates.key_date) BETWEEN 0 AND 21 THEN 21
WHEN DATEDIFF(DAY, GETDATE(), dim_key_dates.key_date) BETWEEN 22 AND 183 THEN 6
WHEN DATEDIFF(DAY, GETDATE(), dim_key_dates.key_date) BETWEEN 184 AND 365 THEN 12
ELSE 0
END
AS [No of days between today and SLA (DATEDIFF)]



FROM red_dw.dbo.dim_key_dates  WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current	  WITH(NOLOCK)
	ON dim_matter_header_current.dim_matter_header_curr_key = dim_key_dates.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health   WITH(NOLOCK)
	ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history    WITH(NOLOCK)
	ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'        
	AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome 	  WITH(NOLOCK)
	ON dim_detail_outcome.dim_matter_header_curr_key = dim_detail_health.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype	WITH(NOLOCK)
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
	ON dim_detail_core_details.client_code = dim_matter_header_current.client_code	 
	AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number

WHERE
hierarchylevel3hist = 'Disease'
AND  type = 'LIMITATION'
AND  ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
AND dim_matter_header_current.matter_number <> 'ML'
  END 

				
GO
