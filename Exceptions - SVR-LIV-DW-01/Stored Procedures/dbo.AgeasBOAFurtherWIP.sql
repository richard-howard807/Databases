SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AgeasBOAFurtherWIP]

AS 
BEGIN
SELECT master_client_code+'-'+master_matter_number AS [Reference]
,matter_description AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,name AS [Matter Owner]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,wip_balance AS WIP
,BOA.BOABalance AS [BOA Balance]
,OpeningBOA.OrgBOA AS [Openning BOA]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT Number,SUM(OrgBOA) AS BOABalance
FROM TE_3E_Prod.dbo.InvMaster
INNER JOIN te_3e_prod.dbo.Matter
 ON LeadMatter=MattIndex
WHERE Number LIKE 'A3003%'
GROUP BY Number
) AS BOA
 ON master_client_code+'-'+master_matter_number=BOA.Number COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT  Number,OrgBOA,InvDate,ROW_NUMBER() OVER (PARTITION BY Number ORDER BY InvDate DESC ) AS xorder
FROM TE_3E_Prod.dbo.InvMaster
INNER JOIN te_3e_prod.dbo.Matter
 ON LeadMatter=MattIndex
WHERE Number LIKE 'A3003%'

AND OrgBOA>0
AND IsReversed=0
) AS OpeningBOA
 ON master_client_code+'-'+master_matter_number=OpeningBOA.Number  COLLATE DATABASE_DEFAULT
 AND OpeningBOA.xorder=1
WHERE client_group_name='Ageas'
 AND present_position='Final bill due - claim and costs concluded'
 AND wip_balance <>0
AND OpeningBOA.OrgBOA IS NOT NULL
AND hierarchylevel3hist='Motor'
AND BOA.BOABalance =0
END 
GO
