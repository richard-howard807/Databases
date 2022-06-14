SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE PROCEDURE [dbo].[MatterFeedbackReconciliation]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2022-04-01'
--SET @EndDate='2022-04-30'



IF OBJECT_ID('tempdb..#JamesTime') IS NOT NULL DROP TABLE #JamesTime
SELECT DISTINCT dim_matter_header_curr_key INTO #JamesTime
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE name='James Holman'



IF OBJECT_ID('tempdb..#SurveyMatters') IS NOT NULL DROP TABLE #SurveyMatters

SELECT dim_matter_header_current.dim_matter_header_curr_key
,CASE WHEN LastBillComposit.BillType='Interim' AND dim_matter_header_current.date_closed_case_management IS NOT NULL AND  hierarchylevel2hist='Legal Ops - LTA' THEN 'LTA Logic set 2'
WHEN LastBillComposit.BillType='Final' AND hierarchylevel2hist='Legal Ops - LTA'  AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50 THEN 'LTA Logic set 1'

WHEN LastBillComposit.BillType='Final' AND hierarchylevel2hist='Legal Ops - Claims'  AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50
AND dim_detail_core_details.present_position IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear') THEN 'Claims Logic set 1'
WHEN LastBillComposit.BillType='Final' AND hierarchylevel2hist='Legal Ops - Claims'  AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50 THEN 'Claims Logic set 2'
WHEN LastBillComposit.BillType='Interim' AND dim_matter_header_current.date_closed_case_management IS NOT NULL AND  hierarchylevel2hist='Legal Ops - Claims' THEN 'Claims Logic set 3'
WHEN LastBillComposit.BillType='Interim'  AND hierarchylevel2hist='Legal Ops - LTA' AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50 AND DATEDIFF(DAY,last_time_transaction_date,GETDATE())>60 THEN 'LTA Logic set 4'
WHEN LastBillComposit.BillType='Interim'  AND hierarchylevel2hist='Legal Ops - Claims' AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50 AND DATEDIFF(DAY,last_time_transaction_date,GETDATE())>60 THEN 'Claims Logic set 4'
WHEN LastBillComposit.BillType='Interim' AND hierarchylevel2hist='Legal Ops - Claims'  AND defence_costs_billed_composite>500  AND ISNULL(wip,0)<50
AND dim_detail_core_details.present_position IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear') THEN 'Claims Logic set 5'


END AS Logic
,hierarchylevel2hist
,dim_detail_core_details.present_position AS [Present Position]
,LastBillComposit.LastBillDate AS [Last Bill Date]
,LastBillComposit.BillType AS [Last Bill Type]
,LastBillComposit.Revenue AS [Last Bill Revenue]
,defence_costs_billed_composite AS [Revenue Billed Composite]
,last_time_transaction_date AS [Last Time Postings]
INTO #SurveyMatters
	FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
	 ON fee_earner_code=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
INNER JOIN 
(
SELECT Bills.client_code AS client_code,
       Bills.matter_number,
       Bills.LastBillDate,
       CASE WHEN Bills.bill_flag='f' THEN 'Final' ELSE 'Interim' END AS BillType,
       Bills.LastBillNum,
       Bills.LastBill ,Bills.Revenue
	   FROM
(SELECT fact_bill_matter_detail_summary.client_code,fact_bill_matter_detail_summary.matter_number
,fact_bill_matter_detail_summary.bill_date AS LastBillDate
,bill_flag,dim_bill.bill_number AS LastBillNum
,fees_total AS Revenue
,ROW_NUMBER() OVER (PARTITION BY fact_bill_matter_detail_summary.client_code,fact_bill_matter_detail_summary.matter_number ORDER BY fact_bill_matter_detail_summary.bill_date DESC) AS LastBill
FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_matter_detail_summary.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_matter_detail_summary.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail_summary.dim_bill_key
WHERE bill_reversed=0

) AS Bills
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = Bills.client_code
 AND dim_matter_header_current.matter_number = Bills.matter_number
WHERE Bills.LastBill=1

) AS LastBillComposit
 ON LastBillComposit.client_code = dim_matter_header_current.client_code
 AND LastBillComposit.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE CONVERT(DATE,LastBillComposit.LastBillDate,103) BETWEEN @StartDate AND @EndDate
AND defence_costs_billed_composite>500



SELECT
RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [File reference]
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,dim_client.client_name AS [Client Name]
,matter_description AS [Matter description]
,date_opened_case_management AS [Date Opened]
,name AS [Matter Owner]
,dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
,dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,matter_category AS [Matter Category]
,work_type_name AS [Matter Type]
,SurveyMatters.[Last Bill Type] AS [Last bill type]
,SurveyMatters.[Last Bill Date] AS [Last bill date]
,SurveyMatters.[Last Bill Revenue] AS [Last bill revenue amount]
,date_closed_case_management AS [Matter closed date]
,ClientAssoc.[Client Name] AS [Client Associate Contact Name]
,ClientAssoc.[Client AssocEmail] AS [Client Associate Contact Email]
,InsurerClientAssoc.[Insurer Client Name] AS [Insurer Associate Contact Name]
,InsurerClientAssoc.[Insurer AssocEmail] AS [Insurer Associate Contact Email]
,clients_claims_handler_surname_forename AS [Clients Claims Handler Name (Claims Division)]
,txtContName AS [Survey Contact Name]
,txtContEmail AS [Survey Contact Email]
,SurveyMatters.Logic
,CASE WHEN txtContEmail IS NOT NULL THEN  ROW_NUMBER() OVER	(PARTITION BY txtContEmail ORDER BY date_opened_case_management DESC) ELSE NULL END AS DuplicateEmail
------------------Sheets----------------------------------
,CASE 
WHEN (CASE WHEN txtContEmail IS NOT NULL THEN  ROW_NUMBER() OVER	(PARTITION BY txtContEmail ORDER BY date_opened_case_management DESC) ELSE NULL END)>1 THEN 'Duplicate Email'
WHEN ClientOptouts.clNo IS NOT  NULL THEN 'Client level opt outs' 
WHEN UPPER(RTRIM(txtContEmail)) IN (SELECT UPPER(RTRIM(txtContEmailVal)) FROM MS_Prod.dbo.udContactEmailOptOut WHERE bitActive=1 ) THEN 'Contact level opt outs'
WHEN UPPER(RTRIM(txtContEmail)) COLLATE DATABASE_DEFAULT IN (SELECT DISTINCT UPPER(RTRIM(email_address))
FROM red_dw.dbo.dim_ia_contact_lists
WHERE dim_ia_contact_lists.dim_lists_key = 67
AND email_address IS NOT NULL) THEN 'Marketing General Opt Outs'
--•	Duplicate contacts
WHEN work_type_code IN ('2038','1114','1077','1143','2039','2041') 
OR fee_earner_code='PRV' 
OR master_client_code IN ('30645','6930','47237','47354','1878','76202','CB001','123739','WB54992')
OR txtContEmail LIKE '%CJM%'
OR UPPER(matter_description) LIKE '%WEIGHTMANS%'
OR UPPER(matter_description) LIKE '%HR RELY%'
--OR UPPER(matter_description) LIKE '%GENERAL%'
OR UPPER(matter_description) LIKE '%INTERNAL%'
OR UPPER(matter_description) LIKE '%TRAINING%'
OR UPPER(matter_description) LIKE '%SECONDMENT%'
OR matter_owner_full_name='James Holman'
OR matter_partner_full_name='James Holman'
OR JamesTime.dim_matter_header_curr_key IS NOT NULL
THEN 'All Internal / CJSM matters / Excluded matter types'
WHEN txtContEmail  IS NULL THEN 'Data Quality Issues'

END AS [Sheets]
,1 AS Matters
,[Revenue Billed Composite]
,SurveyMatters.[Last Time Postings]
FROM #SurveyMatters AS SurveyMatters
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = SurveyMatters.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN ms_prod.dbo.udMICoreGeneralA
 ON ms_fileid=udMICoreGeneralA.fileID
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 
LEFT OUTER JOIN
(
SELECT fileID,STRING_AGG(assocEmail,',') AS [Insurer AssocEmail]
,STRING_AGG(DefaultEmail,',') AS [Insurer ContactDefault]
,STRING_AGG(contName,',') AS [Insurer Client Name]
FROM ms_prod.config.dbAssociates
INNER JOIN MS_Prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT JOIN(SELECT 
    Email.contID,
    Email.Email AS DefaultEmail
FROM 
(
SELECT contID,contEmail AS Email ,ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC)  AS xorder
FROM MS_Prod.dbo.dbContactEmails WHERE   contActive=1
) AS Email
WHERE Email.xorder=1
) AS DefaultEmail
 ON DefaultEmail.contID = dbAssociates.contID
WHERE assocType='INSURERCLIENT'
AND dbAssociates.assocActive=1
AND (DefaultEmail IS NOT NULL OR assocEmail IS NOT NULL)
GROUP BY fileID
) AS InsurerClientAssoc
 ON ms_fileid=InsurerClientAssoc.fileID
LEFT OUTER JOIN 
(
SELECT fileID,STRING_AGG(assocEmail,',') AS [Client AssocEmail]
,STRING_AGG(DefaultEmail,',') AS [Client ContactDefault]
,STRING_AGG(contName,',') AS [Client Name]
FROM ms_prod.config.dbAssociates
INNER JOIN MS_Prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT JOIN(SELECT 
    Email.contID,
    Email.Email AS DefaultEmail
FROM 
(
SELECT contID,contEmail AS Email ,ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC)  AS xorder
FROM MS_Prod.dbo.dbContactEmails WHERE   contActive=1
) AS Email
WHERE Email.xorder=1
) AS DefaultEmail
 ON DefaultEmail.contID = dbAssociates.contID
WHERE assocType='CLIENT'
AND dbAssociates.assocActive=1
AND (DefaultEmail IS NOT NULL OR assocEmail IS NOT NULL)
GROUP BY fileID
) AS ClientAssoc
 ON ms_fileid=ClientAssoc.fileID
LEFT OUTER JOIN (SELECT clNo FROM ms_prod.config.dbClient
INNER JOIN ms_prod.dbo.udExtClient
 ON udExtClient.clID = dbClient.clID
WHERE chkSurOptOut=1) AS ClientOptouts
 ON master_client_code=ClientOptouts.clNo COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN #JamesTime AS JamesTime
 ON JamesTime.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


WHERE SurveyMatters.Logic IS NOT NULL

END

GO
