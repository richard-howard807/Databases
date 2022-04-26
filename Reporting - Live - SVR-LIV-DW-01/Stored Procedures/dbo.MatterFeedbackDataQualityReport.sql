SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MatterFeedbackDataQualityReport] 
AS 

BEGIN

SELECT 
RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [File reference]
,client_name AS [Client Name]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,matter_description AS [Matter description]
,name AS [Matter Owner]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,dim_detail_core_details.present_position AS [Present Position (Claims only) Can just be blank for LTA if easier]
,referral_reason AS [Referral reason (Claims only) Can just be blank for LTA if easier]
,LastBillComposit.LastBillDate AS [Date of last bill]
,DATEDIFF(DAY,LastBillComposit.LastBillDate,GETDATE()) AS [Days since last bill]
,BillType AS [Last bill type Interim of final bill]
,CASE WHEN BillType='Final' THEN 'Yes' ELSE 'No' END  AS [Final bill completed on matter (yes/no)]
,wip AS [WIP Balance]
,last_time_transaction_date AS [Date of last time posting]
,DATEDIFF(DAY,last_time_transaction_date,GETDATE()) AS [Days since last time posting]
,ClientAssoc.[Client AssocEmail]
,ClientAssoc.[Client ContactDefault]
,InsurerClientAssoc.[Insurer AssocEmail]
,InsurerClientAssoc.[Insurer ContactDefault]
,dim_matter_header_current.fixed_fee_amount AS [Fixed Fee Amount]
,clients_claims_handler_surname_forename
,matter_category
,work_type_name

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT Bills.client_code AS client_code,
       Bills.matter_number,
       Bills.LastBillDate,
       CASE WHEN Bills.bill_flag='f' THEN 'Final' ELSE 'Interim' END AS BillType,
       Bills.LastBillNum,
       Bills.LastBill 
	   FROM
(SELECT fact_bill_matter_detail_summary.client_code,fact_bill_matter_detail_summary.matter_number
,fact_bill_matter_detail_summary.bill_date AS LastBillDate
,bill_flag,dim_bill.bill_number AS LastBillNum
,ROW_NUMBER() OVER (PARTITION BY fact_bill_matter_detail_summary.client_code,fact_bill_matter_detail_summary.matter_number ORDER BY fact_bill_matter_detail_summary.bill_date DESC) AS LastBill
FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = fact_bill_matter_detail_summary.client_code
 AND dim_matter_header_current.matter_number = fact_bill_matter_detail_summary.matter_number
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_matter_detail_summary.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail_summary.dim_bill_key
WHERE bill_reversed=0
AND (date_closed_case_management IS NULL)
) AS Bills
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = Bills.client_code
 AND dim_matter_header_current.matter_number = Bills.matter_number
WHERE Bills.LastBill=1

) AS LastBillComposit
 ON   LastBillComposit.client_code = dim_matter_header_current.client_code
 AND  LastBillComposit.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN
(
SELECT fileID,STRING_AGG(assocEmail,',') AS [Insurer AssocEmail]
,STRING_AGG(DefaultEmail,',') AS [Insurer ContactDefault]
FROM ms_prod.config.dbAssociates
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
FROM ms_prod.config.dbAssociates
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
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE dim_matter_header_current.date_closed_case_management IS NULL
 AND master_matter_number <>'0'
 AND hierarchylevel2hist IN ('Legal Ops - LTA','Legal Ops - Claims')

 END
GO
