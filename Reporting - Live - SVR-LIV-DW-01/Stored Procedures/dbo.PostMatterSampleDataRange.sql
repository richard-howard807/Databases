SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[PostMatterSampleDataRange] -- EXEC dbo.PostMatterSampleDataRange '2021-08-01','2021-09-30'
(
@StartDate  AS DATE
,@EndDate  AS DATE
)

AS

BEGIN

SELECT 
                ms_fileid
				,RTRIM(master_client_code)+'-'+master_matter_number AS [3E Reference]
				,dim_matter_header_current.client_name AS [client_name]
                ,dim_matter_header_current.client_code AS [client_code]
				,dim_matter_header_current.matter_number AS [matter_number]
				,matter_description AS [matter_description]
				,hierarchylevel2hist AS [matter_owner_business_line]
				,hierarchylevel3hist AS [matter_owner_practice_area]
				,locationidud AS locationidud
				,final_bill_date AS final_bill_date
				,dim_detail_core_details.[insured_sector]
				,matter_partner_full_name AS [matter_partner_full_name]
				,name AS [matter_owner_name]
				,workemail AS [workemail]
				,dim_client_involvement.[insuredclient_reference]
				,dim_client_involvement.[insurerclient_reference]
				,dim_client_involvement.[clientcontact_name]
				,dim_claimant_thirdparty_involvement.[thirdparty_reference]
				,dim_client_involvement.[insuredclient_name]
				,dim_client_involvement.[insurerclient_name]
				,dim_client.[email]
                ,default_email AS [default_email]
				,dim_matter_header_current.date_opened_case_management AS [matter_opened_case_management_calendar_date]
				,dim_detail_client.[status]
 				,dim_detail_property.[client_contact]
  				,dim_matter_header_current.[default_email_association]
                ,dim_detail_core_details.[clients_claims_handler_surname_forename]
                ,dim_client.[sector]
				,dim_client.[segment]
				,defence_costs_billed_composite AS [fees_total]
				,name AS [matter_owner_displayname]
				,dim_detail_core_details.[present_position]
				,dim_detail_outcome.[date_claim_concluded]
				,dim_detail_outcome.[date_costs_settled]
				,dim_detail_outcome.[outcome_of_case]
				,fact_finance_summary.[defence_costs_billed]
				,fact_finance_summary.defence_costs_billed_composite
				,fact_finance_summary.[wip]
				,last_bill_date AS [last_bill_calendar_date]
				,dim_matter_header_current.date_closed_case_management AS [matter_closed_case_management_calendar_date]
            ,CASE WHEN dim_client_involvement.[insurerclient_name] IS NULL AND dim_client_involvement.[insuredclient_name] IS NULL THEN dim_client_involvement.[clientcontact_name]
            WHEN dim_client_involvement.[insurerclient_name] IS NULL THEN dim_client_involvement.[insuredclient_name] ELSE dim_client_involvement.[insurerclient_name] END AS [Respondent Name]
			,CASE WHEN dim_client_involvement.[insurerclient_reference] IS NULL THEN dim_client_involvement.[insuredclient_reference] ELSE dim_client_involvement.[insurerclient_reference]  END AS [Respondent Ref]
			,CASE WHEN dim_client_involvement.[insurerclient_name] IS NULL AND dim_client_involvement.[insuredclient_name] IS NULL THEN dim_client_involvement.[clientcontact_name]
			 WHEN dim_client_involvement.[insurerclient_name] IS NULL THEN dim_client_involvement.[insuredclient_name] ELSE dim_client_involvement.[insurerclient_name] END  AS [ClientName]

,LastBillComposit.LastBillDate
,LastBillComposit.BillType
,LastBillComposit.LastBillNum
,last_time_transaction_date AS [Last Time Transaction Date]
,ClientAssoc.[Client AssocEmail]
,ClientAssoc.[Client ContactDefault]
,InsurerClientAssoc.[Insurer AssocEmail]
,InsurerClientAssoc.[Insurer ContactDefault]
,[Survey Contact Name]=txtContName
,[Survey Contact Email]=txtContEmail

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN ms_prod.dbo.udMICoreGeneralA
 ON ms_fileid=udMICoreGeneralA.fileID

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
AND (date_closed_case_management IS NULL OR date_closed_case_management>='2019-10-27')
) AS Bills
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = Bills.client_code
 AND dim_matter_header_current.matter_number = Bills.matter_number
WHERE Bills.LastBill=1

) AS LastBillComposit
 ON   LastBillComposit.client_code = dim_matter_header_current.client_code
 AND  LastBillComposit.matter_number = dim_matter_header_current.matter_number
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

WHERE reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2019-10-27')
AND
(
last_bill_date BETWEEN @StartDate AND @EndDate
OR LastBillComposit.LastBillDate BETWEEN @StartDate AND @EndDate
)


END 
GO
