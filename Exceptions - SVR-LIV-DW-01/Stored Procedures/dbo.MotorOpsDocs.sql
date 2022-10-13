SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE PROCEDURE [dbo].[MotorOpsDocs] --EXEC dbo.MotorOpsDocs 'Ageas','Motor'
(
@Client AS NVARCHAR(MAX)
,@Department  AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@FeeEarner AS NVARCHAR(MAX)
) 
AS
BEGIN 

IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit('|', @Department)

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)

IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)


SELECT master_client_code +'-'+master_matter_number AS [MattersphereRef]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,name AS [Case Handler]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,LEFT(DATENAME(MONTH,date_instructions_received),3) + ' ' + CAST(YEAR(date_instructions_received) AS NVARCHAR(5)) AS ReceivedPeriod
,date_instructions_received AS [Date Instructions Recevied]
,LEFT(DATENAME(MONTH,date_claim_concluded),3) + ' '  + CAST(YEAR(date_claim_concluded) AS NVARCHAR(5)) AS ConcludedPeriod
,date_claim_concluded AS [Date Claim Concluded]
,CASE WHEN date_claim_concluded BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1) + 1 
AND   DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1 THEN 1 ELSE 0 END AS ConcludedNo
,CASE WHEN date_instructions_received BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1) + 1 
AND   DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1 THEN 1 ELSE 0 END AS ReceviedNo
,dim_detail_core_details.present_position AS [Present Position]
,dim_detail_core_details.[date_initial_report_sent] 
,outcome_of_case AS Outcome
,CASE WHEN UPPER(outcome_of_case) LIKE '%DISCON%' OR UPPER(outcome_of_case) LIKE '%WON%' OR UPPER(outcome_of_case) LIKE '%STRUC%' THEN 1 ELSE 0 END AS Repudiated
,[TrialDate]
,CASE WHEN Trial.TrialDate BETWEEN CONVERT(DATE,GETDATE(),103) AND DATEADD(DAY,90,CONVERT(DATE,GETDATE(),103)) THEN 1 ELSE 0 END AS UpcomingTrials
,CASE WHEN master_client_code='W15564' THEN 'Sabre' 
WHEN master_client_code='A1001' THEN 'AXA XL'
WHEN master_client_code='T3003' THEN 'Tesco'
WHEN master_client_code='A3003'  AND dim_detail_claim.[name_of_instructing_insurer]='Tesco Underwriting (TU)' THEN 'Tesco'
WHEN master_client_code='A3003' THEN 'Ageas' END AS ClientFilter
,CASE WHEN dim_detail_core_details.present_position='Claim and costs outstanding' OR dim_detail_core_details.present_position IS NULL THEN 1
WHEN dim_detail_core_details.present_position='Claim concluded but costs outstanding' THEN 2
WHEN dim_detail_core_details.present_position='Claim and costs concluded but recovery outstanding' THEN 3
WHEN dim_detail_core_details.present_position='Final bill due - claim and costs concluded' THEN 4
WHEN dim_detail_core_details.present_position='Final bill sent - unpaid' THEN 5
WHEN dim_detail_core_details.present_position='To be closed/minor balances to be clear' THEN 6 END AS PresentPositionOrder
,CASE WHEN dim_detail_core_details.present_position IN 
('Final bill due - claim and costs concluded','Final bill sent - unpaid','To be closed/minor balances to be clear') THEN 'Yes' ELSE 'No' END AS ClosurePosition 
,COALESCE(date_closed_case_management,date_claim_concluded) AS NewClosedDate
,DATEDIFF(DAY,COALESCE(grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_opened_instructions_received),date_initial_report_sent) AS DaysToSend
,DATEDIFF(DAY,COALESCE(grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_opened_instructions_received),GETDATE()) AS Dayswithout
,fact_finance_summary.[damages_paid]  
,fact_finance_summary.[total_tp_costs_paid] 
,DATEDIFF(DAY,date_instructions_received,date_claim_concluded) AS LifeCycle
,Debt.DebtAmount
,CASE WHEN ISNULL(Debt.DebtAmount,0)>=0 THEN 1 ELSE 0 END AS Debtnumber
,CASE WHEN UPPER(dim_detail_core_details.referral_reason) LIKE '%DISP%' THEN 1 ELSE 0 END AS Dispute
,track
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT


LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number


LEFT OUTER JOIN (SELECT fileID AS fileid,MIN(tskDue) AS [TrialDate] FROM ms_prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
WHERE tskDesc LIKE '%Trial date - today%'
AND tskType='KEYDATE'
AND master_client_code IN ('A3003','T3003','W15564','A1001')
GROUP BY fileID
) AS Trial
 ON ms_fileid=Trial.fileid
LEFT OUTER JOIN (SELECT dim_matter_header_current.dim_matter_header_curr_key,SUM(outstanding_total_bill) AS DebtAmount
FROM red_dw.dbo.fact_debt
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_debt.dim_matter_header_curr_key
WHERE master_client_code IN ('A3003','T3003','W15564','A1001')
AND age_of_debt>30
AND outstanding_total_bill>0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key) AS Debt
 ON Debt.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE master_client_code IN ('A3003','T3003','W15564','A1001')
AND reporting_exclusions=0
AND (date_closed_case_management IS NULL OR date_closed_case_management>='2018-01-01')
AND (CASE WHEN master_client_code='W15564' THEN 'Sabre' 
WHEN master_client_code='A1001' THEN 'AXA XL'
WHEN master_client_code='T3003' THEN 'Tesco'
WHEN master_client_code='A3003'  AND dim_detail_claim.[name_of_instructing_insurer]='Tesco Underwriting (TU)' THEN 'Tesco'
WHEN master_client_code='A3003' THEN 'Ageas' END)=@Client
--AND hierarchylevel3hist='Motor'
AND ISNULL(outcome_of_case,'')<>'Returned to Client'

END 
GO
