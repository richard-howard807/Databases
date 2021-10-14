SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [nhs].[NHSRKPISuiteBilling] --EXEC nhs.NHSRKPISuiteBilling '2019-07-01','2019-07-30'
(
@StartDate AS DATE
,@EndDate AS DATE
) 
AS
BEGIN
SELECT CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END  AS [NHSR Ref]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number) AS [Panel ref]
,dim_claimant_thirdparty_involvement.claimant_name AS [Claimant name]
,name AS [Lawyer name]
,AllData.jobtitle AS [Lawyer Grade]
,CASE
	WHEN name IN ('Rachel Kneale', 'Richard Jolly', 'Deborah Bannister', 'Tony Yemmen', 'Paul Thomson') THEN
		'Nominated Partner'
	WHEN AllData.jobtitle IN ('Principal Associate', 'Associate (Costs Lawyer)', 'Principal Associate (Costs Lawyer)') THEN
		'Associate'
	WHEN AllData.jobtitle = 'Chartered Legal Executive' THEN
		'Legal Executive'
	WHEN AllData.jobtitle IN ('Paralegal', 'Costs Draftsperson', 'Intelligence Manager') THEN
		'Paralegal/Other'
	WHEN AllData.jobtitle = 'Legal Director' THEN
		'Partner'
	WHEN AllData.jobtitle = 'Trainee Solicitor' THEN
		'Trainee'
	WHEN AllData.jobtitle = 'Consultant' THEN
		'Solicitor'
	ELSE
		AllData.jobtitle
 END										AS mapped_lawyer_grade
,dim_detail_health.[nhs_type_of_instruction_billing] AS [Type of instruction]
,fact_finance_summary.[fixed_fee_amount] AS [Capped fee]
,CASE WHEN [zurichnhs_date_final_bill_sent_to_client]='1900-01-01' THEN 'Interim'
WHEN zurichnhs_date_final_bill_sent_to_client='01/01/1990  00:00:00' THEN 'Interim'
WHEN [zurichnhs_date_final_bill_sent_to_client] IS NOT NULL THEN 'Final'
ELSE 'Interim' END  AS [Interim/Final]
,dim_detail_core_details.present_position AS [Present Position]
,[zurichnhs_date_final_bill_sent_to_client] AS [Date Final Bill Sent To Client]
,SUM(AllData.[Hours Recorded]) AS [Hours recorded]
,SUM(BillHrs) AS [Hours billed]
,SUM(AllData.[Total profit costs billed]) AS [Total profit costs billed]
,SUM(AllData.[Disbursement billed]) AS [Disbursement billed]
,STRING_AGG(AllData.DisbursementTypes,'; ') AS [Disbursement type]
,SUM(AllData.TotalBilledNet) AS [Total billed (net)]
,SUM(AllData.Vat) AS [Vat]
,STRING_AGG(AllData.NameCounsel,'; ') AS [Name of counsel]
,STRING_AGG(AllData.NameExpert,'; ') AS [Name of other expert]

FROM 
(
SELECT dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
,fact_bill_matter_detail.dim_bill_key AS [Bill Key]
,fact_bill_matter_detail.bill_number AS [Bill Number]
,HoursBilled.MinutesRecorded /60 AS [Hours Billed]
,HoursRecorded.MinutesRecorded /60 AS [Hours Recorded]
,BillHrs
,SUM(fees_total) AS [Total profit costs billed]
,SUM(hard_costs) + SUM(soft_costs) AS [Disbursement billed]
,SUM(bill_total) - SUM(vat) AS TotalBilledNet
,SUM(vat) AS Vat
,SUM(bill_total) AS TotalBilled
,STRING_AGG(DisbursementTypes,'; ')DisbursementTypes
,NameExpert
,NameCounsel
,jobtitle
,name



FROM red_dw.dbo.fact_bill_matter_detail
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail.dim_bill_key
  INNER JOIN red_dw.dbo.dim_matter_header_current
   ON dim_matter_header_current.client_code = fact_bill_matter_detail.client_code
   AND dim_matter_header_current.matter_number = fact_bill_matter_detail.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
-------------------------------------

LEFT OUTER JOIN 
(
SELECT fact_bill_billed_time_activity.dim_matter_header_curr_key,fact_bill_billed_time_activity.dim_bill_key
,SUM(minutes_recorded) /60 AS MinutesRecorded
,SUM(WorkHrs) AS WorkHrs 
,SUM(BillHrs) AS BillHrs
FROM red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill
 ON TimeCard=fact_bill_billed_time_activity.transaction_sequence_number
 AND TimeBill.TimeBillIndex = fact_bill_billed_time_activity.timebillindex --added 01.10.19
WHERE bill_reversed=0
AND master_client_code='N1001'
--AND master_matter_number='6900'
AND bill_date BETWEEN @StartDate AND @EndDate
GROUP BY fact_bill_billed_time_activity.dim_matter_header_curr_key,fact_bill_billed_time_activity.dim_bill_key


) AS HoursBilled
 ON HoursBilled.dim_bill_key = fact_bill_matter_detail.dim_bill_key
 AND HoursBilled.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
---------------------------------------
LEFT OUTER JOIN (SELECT dim_matter_header_curr_key,fact_all_time_activity.dim_bill_key,SUM(minutes_recorded) AS MinutesRecorded
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_all_time_activity.dim_bill_key
WHERE bill_reversed=0
GROUP BY dim_matter_header_curr_key,fact_all_time_activity.dim_bill_key) AS HoursRecorded
 ON HoursRecorded.dim_bill_key = fact_bill_matter_detail.dim_bill_key
 AND HoursRecorded.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT client_code,matter_number,dim_bill_key,STRING_AGG(costype_description,'; ') AS DisbursementTypes  FROM 
(SELECT DISTINCT client_code,matter_number,dim_bill_key,costype_description
FROM red_dw.dbo.fact_disbursements_detail
) AS AllData
GROUP BY client_code,matter_number,dim_bill_key) AS DisbursementTypes
 ON  DisbursementTypes.client_code = dim_matter_header_current.client_code
 AND DisbursementTypes.matter_number = dim_matter_header_current.matter_number
 AND DisbursementTypes.dim_bill_key = fact_bill_matter_detail.dim_bill_key
LEFT OUTER JOIN 
(
SELECT client_code,matter_number,dim_bill_key,STRING_AGG(name,'; ') AS NameExpert  FROM 
(SELECT DISTINCT client_code,matter_number,dim_bill_key,name
FROM red_dw.dbo.fact_disbursements_detail
INNER JOIN red_dw.dbo.dim_payee
 ON dim_payee.dim_payee_key = fact_disbursements_detail.dim_payee_key
WHERE UPPER(costype_description) LIKE '%EXPERT%'
) AS AllData
GROUP BY client_code,matter_number,dim_bill_key
) AS ExpertNames
 ON  ExpertNames.client_code = dim_matter_header_current.client_code
 AND ExpertNames.matter_number = dim_matter_header_current.matter_number
 AND ExpertNames.dim_bill_key = fact_bill_matter_detail.dim_bill_key
LEFT OUTER JOIN 
(
SELECT client_code,matter_number,dim_bill_key,STRING_AGG(name,'; ') AS NameCounsel  FROM 
(SELECT DISTINCT client_code,matter_number,dim_bill_key,name
FROM red_dw.dbo.fact_disbursements_detail
INNER JOIN red_dw.dbo.dim_payee
 ON dim_payee.dim_payee_key = fact_disbursements_detail.dim_payee_key
WHERE UPPER(costype_description) LIKE '%COUNSEL%'
) AS AllData
GROUP BY client_code,matter_number,dim_bill_key
) AS NameCounsel
 ON  NameCounsel.client_code = dim_matter_header_current.client_code
 AND NameCounsel.matter_number = dim_matter_header_current.matter_number
 AND NameCounsel.dim_bill_key = fact_bill_matter_detail.dim_bill_key

   WHERE master_client_code='N1001'
AND bill_date BETWEEN @StartDate AND @EndDate
AND bill_reversed=0
--AND dim_matter_header_current.client_code='N00003' AND dim_matter_header_current.matter_number='00000254'
AND fact_bill_matter_detail.matter_number NOT IN ('VOL001')
GROUP BY dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
,fact_bill_matter_detail.dim_bill_key 
,HoursBilled.MinutesRecorded
,HoursRecorded.MinutesRecorded
,BillHrs
,DisbursementTypes
,NameExpert
,NameCounsel
,fact_bill_matter_detail.bill_number 
,jobtitle
,name
) AS AllData
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = AllData.client_code
 AND dim_matter_header_current.matter_number = AllData.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.client_code = AllData.client_code
 AND dim_detail_health.matter_number = AllData.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = AllData.client_code
 AND fact_finance_summary.matter_number = AllData.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = AllData.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = AllData.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = AllData.client_code
 AND dim_client_involvement.matter_number = AllData.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = AllData.client_code
 AND dim_detail_core_details.matter_number = AllData.matter_number
 
 GROUP BY CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END 
,RTRIM(AllData.client_code) + '-' + RTRIM(AllData.matter_number) 
,dim_claimant_thirdparty_involvement.claimant_name 
,name 
,AllData.jobtitle 
,dim_detail_health.[nhs_type_of_instruction_billing] 
,fact_finance_summary.[fixed_fee_amount]
,dim_detail_core_details.present_position
,[zurichnhs_date_final_bill_sent_to_client]
,master_client_code
,master_matter_number
END
GO
