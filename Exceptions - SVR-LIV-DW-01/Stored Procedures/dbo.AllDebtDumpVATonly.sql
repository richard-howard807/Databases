SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[AllDebtDumpVATonly] 
AS 
BEGIN
--Debt Dump - VAT only

SELECT 
isnull(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber) as 'Client',
isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
,
right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber))
) as 'Matter', 
Matter.Number as '3e ref',
dim_fed_hierarchy_history.hierarchylevel2hist as 'BusinessLine',
dim_fed_hierarchy_history.hierarchylevel3hist as 'PracticeArea',
dim_fed_hierarchy_history.hierarchylevel4hist as 'Team',
dim_client.client_name as 'ClientName',
Matter.DisplayName as 'MatterDesc',
dim_matter_header_current.date_opened_practice_management as 'MatterOpenDate',
dim_fed_hierarchy_history.hierarchylevel4hist as 'MatterOwnerTeam',
dim_fed_hierarchy_history.display_name as 'MatterOwner',
InvPayor.InvNumber,
InvMaster.InvDate,
InvPayor.BalAmt as 'DebtValue',
InvPayor.BalFee as 'OutstandingCosts',
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
dim_detail_core_details.zurich_referral_reason as 'Zurich Referral Reason'

, InvPayor.BalAmt AS [Balance Amount]
, InvPayor.BalBOA AS [Balance BOA]
, InvPayor.BalFee AS [Blance Fee]
, InvPayor.BalHCo AS [Balance Hard Costs]
, InvPayor.BalSCo AS [Balance Soft Costs]
, InvPayor.BalInt AS [Balance Interest]
, InvPayor.BalOth AS [Balance Other]
, InvPayor.BalTax AS [Balance VAT]



FROM 
TE_3E_Prod.dbo.InvPayor  

INNER JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
left join  red_dw.dbo.dim_matter_header_current on master_client_code + '-' + master_matter_number = Matter.Number collate database_default

inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code collate database_default
											   and dim_fed_hierarchy_history.dss_current_flag = 'Y'
											   and dim_fed_hierarchy_history.activeud = 1
inner join TE_3E_Prod.dbo.Client on Client.ClientIndex = Matter.Client

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

WHERE 
 InvPayor.BalTax>0 
AND InvPayor.BalBOA=0
AND InvPayor.BalFee=0
AND InvPayor.BalHCo=0
AND InvPayor.BalSCo=0
AND InvPayor.BalInt=0
AND InvPayor.BalOth=0


--AND InvPayor.InvNumber = '01659941'

END


GO
