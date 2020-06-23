SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CHICLegalServicesMMIReport]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 
BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-05-01'
--SET @EndDate='2020-05-31'

SELECT dim_matter_header_current.client_name AS [Member]
,'Weightmans LLP' AS [Panel Firm]
,date_opened_case_management AS [Instruction Date]
,clientcontact_name AS [Instructing Officer]
,CASE WHEN work_type_name='Administration of Estates' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Banking' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Comm conveyancing (business premises)' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Commercial Contracts' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Commercial drafting (advice)' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Company' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Competition Law' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Construction' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Consumer debt' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Contract' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Corporate transactions' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Data Protection  ' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Debt Recovery' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Defamation' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Direct Selling' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Environmental' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Estate Planning' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Financial' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Financial – Criminal Defence' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Financial – General Advice' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='GDPR' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='General Advice' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Governance & Regulatory' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Injunction' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Injunctions' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Insolvency Corporate' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Insolvency Personal' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Intellectual property' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Invoice Debt' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Invoicing' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Landlord & Tenant - Commercial' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Landlord & Tenant - Disrepair' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Landlord & Tenant - Residential' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Leases-granting,taking,assigning,renewin' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Licensing' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Marketing' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Non-contentious IP & IT Contracts' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Partnership' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Partnerships & JVs' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Planning' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Plot Sales' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Procurement' THEN ''
WHEN work_type_name='Property Dispute Commercial other' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Property Dispute Residential other' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Property Due Diligence' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Property redevelopment' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Remortgage' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Residential conveyancing (houses/flats)' THEN 'Lot 3 - Property & Development'
WHEN work_type_name='Right to buy' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Secured lending' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Share Schemes' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Share Structures & Company Reorganisatio' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Social Housing - Property' THEN 'Lot 2 - Housing & Asset Management'
WHEN work_type_name='Tax Advisory' THEN 'Lot 1 - Corporate, Governance & Finance'
WHEN work_type_name='Trust Administration' THEN 'Lot 1 - Corporate, Governance & Finance'
ELSE 'Outside Lots 1-3'
END AS [Lot]
,RTRIM(master_client_code) +'.'+RTRIM(master_matter_number) AS [Matter Number]
,matter_description AS [Matter Name & brief description of matter]
,matter_partner_full_name AS [Matter Partner]
,clientcontact_reference AS [Fee Code]
,CASE WHEN fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' THEN 'Fixed Fee' ELSE 'Hourly Rate' END  AS [Fee type]
,ISNULL(commercial_costs_estimate,dim_matter_header_current.fixed_fee_amount) AS [Fee quoted (£)]
,bill_date AS [Invoice Date]
,dim_bill.bill_number AS [Invoice Reference Number]
,fees_total AS [Invoice Amount (ex VAT & disbursements)]
,CASE WHEN date_closed_practice_management IS NULL THEN 'N' ELSE 'Y' END  AS [Is matter complete? Y/N]
,fileNotes AS [Comments]


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN ms_prod.config.dbFile
 ON fileID=ms_fileid
WHERE dim_matter_header_current.client_code IN ('W16939','00756630','W15410','00163012'
,'09010229','00013886','00122326','W15586','00779816','00459836','W21685')
AND dim_bill.bill_number <>'PURGE'
AND date_opened_case_management >='2020-07-01'
AND bill_date BETWEEN @StartDate AND @EndDate

ORDER BY bill_date ASC

END
GO
