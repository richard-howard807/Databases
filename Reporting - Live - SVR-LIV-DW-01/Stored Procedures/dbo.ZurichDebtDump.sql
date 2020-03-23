SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ZurichDebtDump] as

/*
==================================================================================================
Jamie Bonner - Ticket #53193
Added columns for Fees, Other Fees, Hard Costs, Soft Costs, VAT and Total Excl VAT
==================================================================================================
*/


SELECT 
ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber) AS 'Client',
ISNULL(RIGHT(Matter.loadnumber, LEN(Matter.loadnumber) - CHARINDEX('-',Matter.loadnumber))
,
RIGHT(Matter.altnumber, LEN(Matter.altnumber) - CHARINDEX('-',Matter.altnumber))
) AS 'Matter', 
Matter.Number AS '3e ref',
dim_fed_hierarchy_history.hierarchylevel2hist AS 'BusinessLine',
dim_fed_hierarchy_history.hierarchylevel3hist AS 'PracticeArea',
dim_fed_hierarchy_history.hierarchylevel4hist AS 'Team',
dim_client.client_name AS 'ClientName',
Matter.DisplayName AS 'MatterDesc',
dim_matter_header_current.date_opened_practice_management AS 'MatterOpenDate',
dim_fed_hierarchy_history.hierarchylevel4hist AS 'MatterOwnerTeam',
dim_fed_hierarchy_history.display_name AS 'MatterOwner',
InvPayor.InvNumber,
InvMaster.InvDate,
InvPayor.BalAmt AS 'DebtValue',
InvPayor.BalFee AS 'OutstandingCosts',
InvPayor.BalOth	AS [Other Fees (Success Fee)],
InvPayor.BalHCo AS [Hard Costs],
InvPayor.BalSCo AS [Soft Costs],
InvPayor.BalTax AS [VAT],
InvPayor.BalFee + InvPayor.BalOth + InvPayor.BalHCo + InvPayor.BalSCo AS [Total Amount Excl. VAT],
datediff(day, InvMaster.InvDate, getdate()) as 'DaysOutstanding',
case
	when datediff(day, InvMaster.InvDate, getdate())	between 0 and 30 then '0 - 30 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 31 and 60 then '31 - 60 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 61 and 90 then '61 - 90 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 91 and 180 then '91 - 180 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 181 and 270 then '181 - 270 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 271 and 360 then '271 - 360 Days'
	when datediff(day, InvMaster.InvDate, getdate())	between 361 and 720 then '361 - 720 Days'
	when datediff(day, InvMaster.InvDate, getdate())	> 720 then 'Greater than 720 Days'
end as 'Days Banding',
Address.FormattedString as 'PayorFormattedString',
dim_detail_core_details.zurich_branch as 'Zurich Branch',
dim_detail_core_details.clients_claims_handler_surname_forename as 'Clients Claims Handler',
dim_client_involvement.insurerclient_reference  'Insurer Client Reference',
dim_detail_core_details.brief_description_of_injury as 'Injury Type',
dim_detail_core_details.zurich_referral_reason as 'Zurich Referral Reason',
dim_detail_client.zurich_debt_department,
dim_detail_client.zurich_reason_not_legal_x,
dim_detail_client.zurich_legal_x,
invoice_status_code,
invoice_status_desc,
dim_bill_debt_narrative.udf_modified_by created_by,
dim_bill_debt_narrative.udf_narrative narrative


FROM 
TE_3E_Prod.dbo.InvPayor  

INNER JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
left join  red_dw.dbo.dim_matter_header_current on master_client_code + '-' + master_matter_number = Matter.Number collate database_default

inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code collate database_default
											   and dim_fed_hierarchy_history.dss_current_flag = 'Y'
											   and dim_fed_hierarchy_history.activeud = 1
inner join TE_3E_Prod.dbo.Client on Client.ClientIndex = Matter.Client
AND Client.Number = 'Z1001'

INNER JOIN TE_3E_Prod.dbo.Payor ON Payor.PayorIndex = InvPayor.Payor
LEFT OUTER JOIN TE_3E_Prod.dbo.Site ON Site.SiteIndex = CASE WHEN Payor.StmtSite IS NULL THEN Payor.Site ELSE Payor.StmtSite END
LEFT OUTER JOIN TE_3E_Prod.dbo.Address ON Address.AddrIndex = Site.Address

left join red_dw.dbo.fact_dimension_main on fact_dimension_main.client_code = isnull(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber) collate database_default
										and fact_dimension_main.matter_number = isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
																						,
																						right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber))
																						)  collate database_default

inner join red_dw.dbo.dim_client on dim_client.dim_client_key = fact_dimension_main.dim_client_key
inner join red_dw.dbo.dim_detail_core_details 
			on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key

inner join red_dw.dbo.dim_client_involvement 
	on dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

INNER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key

LEFT JOIN red_dw.dbo.dim_bill_debt_narrative ON InvPayor.InvNumber COLLATE DATABASE_DEFAULT = dim_bill_debt_narrative.bill_number


WHERE 
InvPayor.BalAmt <> 0
AND LOWER(Address.FormattedString) LIKE '%zurich%'
--and InvPayor.InvNumber = '01862579'

GO
