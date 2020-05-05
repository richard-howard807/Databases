SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2019-08-16
Description:		Data for NHSR CAR Dashboard, rolling 12 months
Ticket:				29094
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [nhs].[NHSR_CAR_Dashboard] 
AS
BEGIN


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Maindata') IS NOT NULL
    DROP TABLE #Maindata 

IF OBJECT_ID('tempdb..#SummaryData') IS NOT NULL
    DROP TABLE #SummaryData 


SELECT --TOP 100* 

       header.master_client_code AS [Master Client Code]
       , header.master_matter_number AS [Master Matter Number]
       , header.client_group_name AS [Client Group Name]
	   , emp_hierarchy.hierarchylevel4hist AS [Team]
       , header.matter_owner_full_name AS [Matter Owner]
       , emp_hierarchy.windowsusername AS [Windows Username]
       , health.nhs_scheme AS [NHS Scheme]
       , CASE WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [Scheme]
       , health.[nhs_claim_status] AS [NHS Claim Status]
       , CASE WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid = 0 THEN '£0'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 1 AND 5000 THEN '£1-5,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 5001 AND 10000 THEN '£5,001-10,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 10001 AND 25000 THEN '£10,001-25,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 25001 AND 50000 THEN '£25,001-50,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid >= 50001  THEN '£50,001+'

              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND health.[nhs_claim_status] = 'Periodical payments' THEN 'PPOs'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid = 0 THEN '£0'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 1 AND 50000 THEN '£1-50,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 50001 AND 250000 THEN '£50,001-250,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 250001 AND 500000 THEN '£250,001-500,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 500001 AND 1000000 THEN '£500,001-1,000,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid >= 1000001 THEN '£1m+'

        END AS [Banding]

       , fin.damages_paid AS [Damages Paid]
       , fin.defence_costs_billed + fin.disbursements_billed AS [Defence Costs inc Disbs]
       , emp.locationidud [Matter Owner Office]
       , CASE WHEN emp.locationidud IN ('London NFL','London Hallmark') THEN 'London'
              WHEN emp.locationidud IN ('Liverpool','Manchester Spinningfields') THEN 'Liverpool'
              ELSE emp.locationidud
		 END [Office]
       , header.date_closed_case_management AS [Date Case Closed]
       , outcome.date_claim_concluded AS [Date Claim Concluded]
       , outcome.date_costs_settled AS [Date Costs Settled]
	   , health.[zurichnhs_date_final_bill_sent_to_client] AS [Final Bill Sent to Client]
       , core.date_instructions_received AS [Date Instructions Received]
       , CONVERT(DECIMAL(16,4),shelf_life.elapsed_days_conclusion)/365 AS [Shelf Life]
       , shelf_life.days_to_send_report AS [Days to Send Report]
       , core.referral_reason AS [Referral Reason]
       , outcome.outcome_of_case AS [Outcome]
       , tpi.claimant_name AS [Claimant Name]
	   , core.date_initial_report_sent AS [Date Initial Report Sent]
       , DATEDIFF(DAY,core.date_instructions_received, core.date_initial_report_sent) [Days to Send Initial Report] 

       , date_claim_concluded.cal_month_no AS date_claim_concluded_cal_month_no
       , date_claim_concluded.cal_year AS date_claim_concluded_cal_year
       , date_final_bill_sent_to_client.cal_month_no AS date_final_bill_sent_to_client_cal_month_no
       , date_final_bill_sent_to_client.cal_year AS date_final_bill_sent_to_client_cal_year  
	   , date_instructions_received.cal_month_no AS date_instructions_received_cal_month_no
       , date_instructions_received.cal_year AS date_instructions_received_cal_year  




          into #Maindata

FROM red_dw.dbo.fact_dimension_main main
INNER JOIN red_dw.dbo.dim_matter_header_current header ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.fact_finance_summary fin ON fin.master_fact_key = main.master_fact_key
INNER JOIN red_dw.dbo.dim_detail_health health ON health.dim_detail_health_key = main.dim_detail_health_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history emp_hierarchy ON emp_hierarchy.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee emp ON emp_hierarchy.dim_employee_key = emp.dim_employee_key  
LEFT JOIN red_dw.dbo.dim_detail_outcome outcome ON outcome.dim_detail_outcome_key = main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_detail_elapsed_days shelf_life ON main.master_fact_key = shelf_life.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement tpi ON tpi.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key
left outer join red_dw..dim_date date_claim_concluded on date_claim_concluded.calendar_date = outcome.date_claim_concluded
left outer join red_dw..dim_date date_final_bill_sent_to_client on date_final_bill_sent_to_client.calendar_date = health.zurichnhs_date_final_bill_sent_to_client
left outer join red_dw..dim_date date_instructions_received on date_instructions_received.calendar_date = core.date_instructions_received


WHERE header.client_group_code = '00000003'
AND header.reporting_exclusions = 0
AND core.referral_reason IS NOT NULL 
AND core.referral_reason IN ('Dispute on liability and quantum','Dispute on quantum','Dispute on liability','Infant approval', 'Costs dispute','Dispute on Liability','Infant Approval')
AND (outcome.outcome_of_case IS NULL OR  outcome.outcome_of_case <> 'Exclude from reports')
AND health.nhs_scheme IN ('CNST','ELS','DH CL','DH Liab','LTPS','PES')
AND health.nhs_scheme IS NOT NULL 
--AND NOT (header.date_closed_case_management IS NULL AND outcome.date_claim_concluded IS NULL AND outcome.date_costs_settled IS NULL AND health.zurichnhs_date_final_bill_sent_to_client IS NULL)

;



With Repoting_Groups as (
              select distinct a.cal_year Reporting_cal_year
							, a.cal_month_no Reporting_cal_month_no
                            , DATENAME(month, DATEADD(month, a.cal_month_no-1, CAST('2008-01-01' AS datetime))) + ' ' + cast(a.cal_year as varchar(4)) Reporting_Group
							, b.cal_month_no
							, b.cal_year
              from red_dw..dim_date a
              inner join (select cal_month_no, cal_year, calendar_date from red_dw..dim_date) b 
                                         on b.calendar_date >= dateadd(mm, -11, a.calendar_date) 
                                         and a.cal_year >= b.cal_year
                                         and b.calendar_date <= a.calendar_date                                                   
              where a.calendar_date >= '20190601'
              and a.calendar_date <= getdate()
              --     and a.cal_year = 2019 and a.cal_month_no = 7
              --     order by 1, 2, 5, 4
              )

SELECT 
	PanelAverages.[Panel Damages Paid]
	, PanelAverages.[Panel Shelf life (yrs)]
	, PanelAverages.[Panel Defence Costs]
	, NHSRData.*
	INTO #SummaryData
 FROM (
select b.Reporting_Group
		, Reporting_cal_year
		, Reporting_cal_month_no
       ,'Concluded' Reporting_Line
       , a.*
       , a.[Damages Paid] Reporting_Costs
       , a.[Shelf Life] Reporting_Shelf_Life
from #maindata a
inner join Repoting_Groups b on a.date_claim_concluded_cal_month_no = b.cal_month_no and a.date_claim_concluded_cal_year = b.cal_year
--where master_client_code = 'N1001' and master_matter_number = 15706

union all

select b.Reporting_Group
		, Reporting_cal_year
		, Reporting_cal_month_no
       ,'FinalBillSent' Reporting_Line
       , a.*
       , a.[Defence Costs inc Disbs] 
       , null Reporting_Shelf_Life
from #maindata a
inner join Repoting_Groups b on a.date_final_bill_sent_to_client_cal_month_no = b.cal_month_no and a.date_final_bill_sent_to_client_cal_year = b.cal_year
--where master_client_code = 'N1001' and master_matter_number = 15706
--order by 1

UNION ALL 

select b.Reporting_Group
		, Reporting_cal_year
		, Reporting_cal_month_no
       ,'Opened' Reporting_Line
       , a.*
	   , NULL Reporting_Costs
       , NULL Reporting_Shelf_Life
from #maindata a
inner join Repoting_Groups b on a.date_instructions_received_cal_month_no = b.cal_month_no and a.date_instructions_received_cal_year = b.cal_year

) AS NHSRData

LEFT OUTER JOIN Reporting.nhs.PanelAverages ON PanelAverages.Scheme=NHSRData.Scheme
AND PanelAverages.Banding=NHSRData.Banding



SELECT a.*,b.[DefenceCostsTarget],b.[ShelfLifeTarget],b.[DamagesTarget]
FROM #SummaryData AS a

LEFT OUTER JOIN (SELECT [Master Client Code]
						,[Master Matter Number]
						,Reporting_Group
						,Reporting_Line
						--,CASE WHEN Reporting_Line='FinalBillSent' AND Reporting_Costs IS NULL THEN [Panel Defence Costs] 
						--	WHEN Reporting_Line='FinalBillSent' THEN Reporting_Costs*0.9 ELSE NULL END AS [DefenceCostsTarget]
						--,CASE WHEN Reporting_Line='Concluded' AND Reporting_Costs IS NULL THEN [Panel Damages Paid] 
						--	WHEN Reporting_Line='Concluded' THEN Reporting_Costs*0.9 ELSE NULL END AS [DamagesTarget]
						--,CASE WHEN Reporting_Line='Concluded' AND Reporting_Shelf_Life IS NULL THEN [Panel Shelf life (yrs)] 
						--	WHEN Reporting_Line='Concluded' THEN Reporting_Shelf_Life*0.9 ELSE NULL END AS [ShelfLifeTarget]
						,CASE WHEN Reporting_Line='FinalBillSent' AND Reporting_Costs IS NULL THEN NULL
							WHEN Reporting_Line='FinalBillSent' THEN Reporting_Costs*0.9 ELSE NULL END AS [DefenceCostsTarget]
						,CASE WHEN Reporting_Line='Concluded' AND Reporting_Costs IS NULL THEN NULL 
							WHEN Reporting_Line='Concluded' THEN Reporting_Costs*0.9 ELSE NULL END AS [DamagesTarget]
						,CASE WHEN Reporting_Line='Concluded' AND Reporting_Shelf_Life IS NULL THEN NULL 
							WHEN Reporting_Line='Concluded' THEN Reporting_Shelf_Life*0.9 ELSE NULL END AS [ShelfLifeTarget]
FROM #SummaryData WHERE Reporting_Group='June 2019'
) AS b
 ON b.[Master Client Code] = a.[Master Client Code]
 AND b.[Master Matter Number] = a.[Master Matter Number]
 AND b.Reporting_Group=a.Reporting_Group
 AND b.Reporting_Line=a.Reporting_Line




END
GO
