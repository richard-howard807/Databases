SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
	20170928 LD Added additional payor columns
	10-01-2018 JL Added in join for HSD and team manager 1.1

*/



CREATE PROC [dbo].[AllDebtDumpMIB] AS 

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 
	master_client.client_partner_name AS 'master_client_partner',
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
	dim_detail_core_details.zurich_branch AS 'Zurich Branch',
	dim_detail_core_details.clients_claims_handler_surname_forename AS 'Clients Claims Handler',
	dim_client_involvement.insurerclient_reference  'Insurer Client Reference',
	dim_detail_core_details.brief_description_of_injury AS 'Injury Type',
	dim_detail_core_details.zurich_referral_reason AS 'Zurich Referral Reason',
	invoice_status_code,
	invoice_status_desc,
	CASE WHEN ISNUMERIC(dim_matter_header_current.master_client_code) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR, dim_matter_header_current.master_client_code), 8) 
							 ELSE CAST(RTRIM(dim_matter_header_current.master_client_code) AS VARCHAR(8)) END  AS master_client_code
	-- LD 20170928

	, InvPayor.BalBOA AS [Balance BOA]
	, InvPayor.BalHCo AS [Balance Hard Costs]
	, InvPayor.BalSCo AS [Balance Soft Costs]
	, InvPayor.BalInt AS [Balance Interest]
	, InvPayor.BalOth AS [Balance Other]
	, InvPayor.BalTax AS [Balance VAT]
	, InvPayor.OrgAmt
	, InvPayor.OrgFee
	, InvPayor.OrgHCost
	, InvPayor.OrgScost
	, InvPayor.OrgTax
	, dim_fed_hierarchy_history.worksforname AS [Team Manager] /*1.1*/
	, hsd.name as HSD /*1.1*/
	
	-- show total unpaid fees, disbs and VAT on each invoice? 

FROM  TE_3E_Prod.dbo.InvPayor  
INNER JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
INNER JOIN TE_3E_Prod.dbo.Client ON Client.ClientIndex = Matter.Client
INNER JOIN TE_3E_Prod.dbo.Payor ON Payor.PayorIndex = InvPayor.Payor
LEFT OUTER JOIN TE_3E_Prod.dbo.[Site] ON [Site].SiteIndex = CASE WHEN Payor.StmtSite IS NULL THEN Payor.[Site] ELSE Payor.StmtSite END
LEFT OUTER JOIN TE_3E_Prod.dbo.[Address] ON [Address].AddrIndex = [Site].[Address]

LEFT JOIN red_dw.dbo.dim_matter_header_current ON master_client_code + '-' + master_matter_number = Matter.Number COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code COLLATE DATABASE_DEFAULT
											   AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
											   AND dim_fed_hierarchy_history.activeud = 1
LEFT JOIN (SELECT distinct name, employeeid, hierarchylevel3hist  from red_dw.dbo.dim_fed_hierarchy_history where management_role_one = 'HoSD' ) as hsd on hsd.hierarchylevel3hist = dim_fed_hierarchy_history.hierarchylevel3hist /*1.1*/
LEFT JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.client_code = ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber) COLLATE DATABASE_DEFAULT
										AND fact_dimension_main.matter_number = ISNULL(RIGHT(Matter.loadnumber, LEN(Matter.loadnumber) - CHARINDEX('-',Matter.loadnumber))
																						,
																						RIGHT(Matter.altnumber, LEN(Matter.altnumber) - CHARINDEX('-',Matter.altnumber))
																						)  COLLATE DATABASE_DEFAULT

LEFT JOIN red_dw.dbo.dim_client					ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_dw.dbo.dim_detail_core_details	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_client_involvement		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_bill_debt_narrative	ON InvPayor.InvNumber COLLATE DATABASE_DEFAULT = dim_bill_debt_narrative.bill_number
LEFT JOIN red_dw.dbo.dim_client AS master_client ON CASE WHEN ISNUMERIC(dim_matter_header_current.master_client_code) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR,dim_matter_header_current.master_client_code), 8) 
															ELSE CAST(RTRIM(dim_matter_header_current.master_client_code)  AS VARCHAR(8)) END
                         = master_client.client_code

WHERE 
InvPayor.BalAmt <> 0
AND dim_client.client_name LIKE '%Motor Insurers%'

--and InvPayor.InvNumber = '01659941'



ORDER BY ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber), 
Address.FormattedString
END
GO
