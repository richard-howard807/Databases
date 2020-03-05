SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [marketing].[MIPIM] 
AS
BEGIN
SELECT client_name AS [client name]
,red_dw.dbo.dim_matter_header_current.client_code AS [Client]
,red_dw.dbo.dim_matter_header_current.matter_number AS [Matter Number]
,date_opened_case_management AS [Date opened]
,date_closed_practice_management AS [Date closed]
,name AS [FE name]
,matter_description AS [Matter description]
,hierarchylevel4hist AS [Team]
,department_name AS [Department]
,work_type_name AS [Work type]
,work_type_group AS [worktype group]
,Revenue18.Revenue AS [Revenue 18/19]
,Revenue19.Revenue AS [Revenue 19/20]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_department
 ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN (SELECT client_code,matter_number,SUM(fees_total) AS Revenue 
FROM red_dw.dbo.fact_bill_matter_detail 
WHERE bill_date BETWEEN '2018-05-01' AND '2019-04-30'
GROUP BY client_code,matter_number) AS Revenue18
 ON Revenue18.client_code = dim_matter_header_current.client_code
 AND Revenue18.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code,matter_number,SUM(fees_total) AS Revenue 
FROM red_dw.dbo.fact_bill_matter_detail 
WHERE bill_date BETWEEN '2019-05-01' AND '2020-04-30'
GROUP BY client_code,matter_number) AS Revenue19
 ON Revenue19.client_code = dim_matter_header_current.client_code
 AND Revenue19.matter_number = dim_matter_header_current.matter_number

LEFT OUTER JOIN (
SELECT fileID,contName AS InsuredClient
 FROM ms_prod.config.dbAssociates 
 INNER JOIN ms_prod.config.dbContact 
 ON dbContact.contID = dbAssociates.contID 
WHERE assocType='INSUREDCLIENT'
) AS InsuredClient 
 ON InsuredClient.fileID=ms_fileid
WHERE date_opened_case_management>='2019-01-01'
AND 
(UPPER(client_name) IN 
(
'ARLINGTON INSURANCE SERVICES LTD','ATELIER TEN','CUTHBERT WHITE','CYNERGY BANK','DEXTER MOREN ASSOCIATES'
,'DUAL ASSET UNDERWRITING LIMITED','EVOLVE UK','FUNDING PROCUREMENT CONSULTANCY','GIA BUILDING CONSULTANCY'
,'ICENI PROJECTS LIMITED','INTELLIGENT REAL ESTATE DUE DILIGENCE LIMITED','INVESTEC BANK PLC','KEPPIE DESIGN LTD'
,'KINGSLEY NAPLEY','LEGAL & CONTINGENCY LIMITED','LIGHT & LEGAL INDEMNITY SOLUTIONS','MALCOLM HOLLIS LLP','MOUNT STREET GROUP'
,'P J LEGGATE & CO LIMITED','PEARSON PROPERTY CONSULTANCY LTD','PERITUS CORPORATE FINANCE LIMITED','PGIM FINANCIAL LIMITED'
,'REGENT CAPITAL PUBLIC LIMITED COMPANY','RUNWAY EAST','SARUM PROPERTIES','SILK PROPERTY GROUP','STEWART TITLE LIMITED'
,'THE LORENZ CONSULTANCY','TRIDENT BUILDING CONSULTANCY LIMITED','TROPHAEUM ASSET MANAGEMENT LTD','UNITED TRUST BANK LIMITED'
,'WALKERS GLOBAL','INVESTEC BANK (CHANNEL ISLANDS) LIMITED'
,'TRIDENT HOUSING ASSOCIATION','PEARSON PROPERTY PROMOTIONS LTD','THE MEMBERS OF THE 2009-10 REGENT CAPITAL ST ANDREW''S HOUSE SYNDICATE'
,'2013/2014 REGENT CAPITAL LIVERPOOL NO. 6 SYNDICATE'
)
OR UPPER(InsuredClient) IN 
(
'ARLINGTON INSURANCE SERVICES LTD','ATELIER TEN','CUTHBERT WHITE','CYNERGY BANK','DEXTER MOREN ASSOCIATES'
,'DUAL ASSET UNDERWRITING LIMITED','EVOLVE UK','FUNDING PROCUREMENT CONSULTANCY','GIA BUILDING CONSULTANCY'
,'ICENI PROJECTS LIMITED','INTELLIGENT REAL ESTATE DUE DILIGENCE LIMITED','INVESTEC BANK PLC','KEPPIE DESIGN LTD'
,'KINGSLEY NAPLEY','LEGAL & CONTINGENCY LIMITED','LIGHT & LEGAL INDEMNITY SOLUTIONS','MALCOLM HOLLIS LLP','MOUNT STREET GROUP'
,'P J LEGGATE & CO LIMITED','PEARSON PROPERTY CONSULTANCY LTD','PERITUS CORPORATE FINANCE LIMITED','PGIM FINANCIAL LIMITED'
,'REGENT CAPITAL PUBLIC LIMITED COMPANY','RUNWAY EAST','SARUM PROPERTIES','SILK PROPERTY GROUP','STEWART TITLE LIMITED'
,'THE LORENZ CONSULTANCY','TRIDENT BUILDING CONSULTANCY LIMITED','TROPHAEUM ASSET MANAGEMENT LTD','UNITED TRUST BANK LIMITED'
,'WALKERS GLOBAL','INVESTEC BANK (CHANNEL ISLANDS) LIMITED'
,'TRIDENT HOUSING ASSOCIATION','PEARSON PROPERTY PROMOTIONS LTD','THE MEMBERS OF THE 2009-10 REGENT CAPITAL ST ANDREW''S HOUSE SYNDICATE'
,'2013/2014 REGENT CAPITAL LIVERPOOL NO. 6 SYNDICATE'
)

)

END
GO
