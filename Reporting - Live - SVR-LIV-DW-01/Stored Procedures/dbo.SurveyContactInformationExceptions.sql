SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[SurveyContactInformationExceptions]
(
@Division AS NVARCHAR(MAX)
,@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)
AS
BEGIN 

SELECT ListValue  INTO #Division FROM Reporting.dbo.[udt_TallySplit]('|', @Division)
SELECT ListValue  INTO #Department FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT 
RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [File reference]
,client_name AS [Client Name]
,matter_description AS [Matter description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,name AS [Matter Owner]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,matter_category AS [Matter Category]
,dim_matter_worktype.work_type_name AS [Matter Type]
,ClientAssoc.[Client Name] AS [Client Associate Contact Name]
,ClientAssoc.[Client ContactDefault] AS [Client Associate Contact Email]
,InsurerClientAssoc.[Insurer Client Name] AS [Insurer Associate Contact Name]
,InsurerClientAssoc.[Insurer ContactDefault] AS [Insurer Associate Contact Email]
,clients_claims_handler_surname_forename AS [Clients Claims Handler Name (Claims Division)]
,txtContName AS [Survey Contact Name]
,txtContEmail AS [Survey Contact Email]
----------------------------------
,last_time_transaction_date AS [Last Time Posting]
,LastBillComposit.BillType AS [Last Bill Type]
,DATEDIFF(DAY,ISNULL(last_time_transaction_date,GETDATE()),GETDATE()) AS [Days Since Last Time Posting]
,dim_detail_core_details.present_position
,dim_detail_core_details.fixed_fee
,fixed_fee_amount
 FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fee_earner_code=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Division AS Division  ON Division.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel2hist COLLATE DATABASE_DEFAULT
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
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
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneralA
 ON  ms_fileid=udMICoreGeneralA.fileid
LEFT OUTER JOIN MS_Prod.config.dbFile
ON ms_fileid=dbFile.fileID
LEFT OUTER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udExtClient
 ON udExtClient.clID = dbClient.clID
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
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
AND dim_matter_header_current.date_opened_case_management<'2022-05-12'
) AS Bills
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = Bills.client_code
 AND dim_matter_header_current.matter_number = Bills.matter_number
WHERE Bills.LastBill=1

) AS LastBillComposit
 ON   LastBillComposit.client_code = dim_matter_header_current.client_code
 AND  LastBillComposit.matter_number = dim_matter_header_current.matter_number
 WHERE dim_matter_header_current.date_opened_case_management<'2022-05-12'
AND dim_matter_header_current.date_closed_case_management IS NULL
AND master_matter_number<>'0'
AND (txtContEmail IS NULL OR txtContName IS NULL)
AND work_type_code NOT  IN ('2038','1114','1077','1143','2039','2041')
AND fee_earner_code <>'PRV'
AND client_name NOT LIKE '%Weightmans%'
AND master_client_code NOT IN ('30645','6930','47237','47354','1878','76202','CB001','123739')
AND UPPER(matter_description) NOT LIKE '%HR RELY%'
AND UPPER(matter_description) NOT LIKE '%GENERAL%'
AND UPPER(matter_description) NOT LIKE '%INTERNAL%'
AND UPPER(matter_description) NOT LIKE '%TRAINING%'
AND UPPER(matter_description) NOT LIKE '%SECONDMENT%'
AND matter_owner_full_name<>'James Holman'
AND matter_partner_full_name<>'James Holman'
AND chkSurOptOut  IS NULL
-----
AND DATEDIFF(DAY,ISNULL(last_time_transaction_date,GETDATE()),GETDATE())<=180
AND ISNULL(LastBillComposit.BillType,'')<>'Final'
AND ISNULL(dim_detail_core_details.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND (CASE WHEN dim_detail_core_details.fixed_fee='Yes' AND fixed_fee_amount BETWEEN 0.01 AND 499.99 THEN 1 ELSE 0 END)=0

END
GO
