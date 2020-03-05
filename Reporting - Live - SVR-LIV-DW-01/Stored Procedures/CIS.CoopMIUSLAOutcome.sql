SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [CIS].[CoopMIUSLAOutcome]
AS
BEGIN
DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE
SET @StartDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101))
SET @EndDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),101))


DELETE FROM CIS.MIUSLAONOutcomes
WHERE [Year Period]=YEAR(@StartDate)
AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10))

INSERT INTO CIS.MIUSLAONOutcomes
(
client,matter,
Outcome
,[Date Claim Claim Concluded]
,[Total Concluded]
,[Trial Win]
,[Discontinued]  
,[Struck out] 
,[Reduced Settlement Saving Less 50]
,[Reduced Settlement Saving greater 50]
,[Damages Paid] 
,[Damage Reserve]
,[Savings]
,Litigation
,[Year Period]
,[Period]
,[InsertedDate]
)
SELECT dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS matter
,outcome_of_case AS Outcome
,date_claim_concluded AS [Date Claim Claim Concluded]
,1 AS [Total Concluded]
,CASE WHEN outcome_of_case  LIKE '%Won%' THEN 1 ELSE 0 END [Trial Win]
,CASE WHEN outcome_of_case LIKE '%Discontinued%' THEN 1 ELSE 0 END AS [Discontinued]  
,CASE WHEN outcome_of_case LIKE '%Struck%' THEN 1 ELSE 0 END AS [Struck out] 
,CASE WHEN outcome_of_case LIKE '%Settled%'  AND (CASE WHEN damages_reserve >0 THEN (damages_reserve -  damages_paid)/damages_reserve ELSE NULL END *100) <=50 THEN 1 ELSE 0 END [Reduced Settlement Saving Less 50]
,CASE WHEN outcome_of_case LIKE '%Settled%'  AND (CASE WHEN damages_reserve >0 THEN (damages_reserve -  damages_paid)/damages_reserve ELSE NULL END *100) >50 THEN 1 ELSE 0 END [Reduced Settlement Saving greater 50]
,damages_paid AS [Damages Paid] 
,damages_reserve AS [Damage Reserve]
,CASE WHEN damages_reserve >0 THEN (damages_reserve -  damages_paid)/damages_reserve ELSE NULL END *100 AS[Savings]
,CASE WHEN ISNULL(proceedings_issued,'')='Yes' THEN 'Litigated'  ELSE 'Non-Litigated' END AS Litigation
,YEAR(@StartDate) AS[Year Period]
,'P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) AS [Period]
,CONVERT(DATE,GETDATE(),103) AS [InsertedDate]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_department
 ON dim_matter_header_current.dim_department_key=dim_department.dim_department_key
INNER JOIN red_dw.dbo.fact_dimension_main 
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
  ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code=fed_code collate database_default
AND dim_fed_hierarchy_history.dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number 

WHERE (dim_matter_header_current.client_code IN ('00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421') 
		AND ((hierarchylevel4hist LIKE '%Motor Investigation Unit%' or hierarchylevel4hist Like 'Central Contracts%' OR hierarchylevel4hist IN ('Motor Fraud','Organised Fraud'))
				and (dim_department.department_code IN('0028','0003')
					OR dim_matter_worktype.work_type_code in ('1200','1201','1202','1203','1204','1205','1206','1207')
					)
				OR case_id IN(SELECT case_id FROM CoopHistoricalCases)
			  )
	   OR case_id IN(SELECT case_id FROM CoopHistoricalCases)
	  
	   )
AND date_claim_concluded BETWEEN @StartDate AND @EndDate
AND ISNULL(referral_reason,'') NOT IN ('Infant Approval','Advice only')


END

GO
