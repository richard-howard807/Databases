SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- LD added additional fields 20170713 Webby 244046
-- ES added arcs narrative 20180516 webby 313487
-- ES added arcs created by 20180517 webby 313487

CREATE PROCEDURE [dbo].[AIGDebtDump] 
AS
BEGIN


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
InvPayor.OrgTax AS 'Tax',
DATEDIFF(DAY, InvMaster.InvDate, GETDATE()) AS 'DaysOutstanding',
CASE
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 0 AND 30 THEN '0 - 30 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 31 AND 60 THEN '31 - 60 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 61 AND 90 THEN '61 - 90 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 91 AND 180 THEN '91 - 180 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 181 AND 270 THEN '181 - 270 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 271 AND 360 THEN '271 - 360 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 361 AND 720 THEN '361 - 720 Days'
	WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	> 720 THEN 'Greater than 720 Days'
END AS 'Days Banding',
Address.FormattedString AS 'PayorFormattedString',

dim_detail_core_details.aig_reference AS 'AIG Reference',
dim_detail_core_details.clients_claims_handler_surname_forename AS 'Clients Claims Handler',
dim_detail_client.aig_litigation_number 'AIG LIT Number',
dim_client_involvement.insurerclient_reference  'Insurer Client Reference',
dim_detail_core_details.brief_description_of_injury AS 'Injury Type',
invoice_status_code,
invoice_status_desc,
dim_detail_core_details.fixed_fee
-- LD Added 
,Payor.DisplayName
, InvPayor.BalAmt AS [Balance Amount]
, InvPayor.BalBOA AS [Balance BOA]
, InvPayor.BalFee AS [Blance Fee]
, InvPayor.BalHCo AS [Balance Hard Costs]
, InvPayor.BalSCo AS [Balance Soft Costs]
, InvPayor.BalInt AS [Balance Interest]
, InvPayor.BalOth AS [Balance Other]
, InvPayor.BalTax AS [Balance VAT]
, dim_bill_debt_narrative.created_by
, dim_bill_debt_narrative.narrative


FROM 
TE_3E_Prod.dbo.InvPayor  

INNER JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
LEFT JOIN  red_dw.dbo.dim_matter_header_current ON master_client_code + '-' + master_matter_number = Matter.Number COLLATE DATABASE_DEFAULT

INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code COLLATE DATABASE_DEFAULT
											   AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
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
AND dim_client.client_group_name = 'AIG'
inner join red_dw.dbo.dim_detail_core_details 
			on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
inner join red_dw.dbo.dim_detail_client 
			on dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key


inner join red_dw.dbo.dim_client_involvement 
	on dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_bill_debt_narrative ON InvPayor.InvNumber COLLATE DATABASE_DEFAULT = dim_bill_debt_narrative.bill_number

WHERE 
InvPayor.BalAmt <> 0  

END


GO
