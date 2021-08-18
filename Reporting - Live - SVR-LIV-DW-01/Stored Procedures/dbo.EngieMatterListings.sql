SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[EngieMatterListings]

AS 

BEGIN 

SELECT master_client_code+ '-'+master_matter_number AS [Matter Number]
,date_opened_case_management AS [File open date]
,matter_owner_full_name AS [Case handler]
,matter_description AS [Matter description]
,fileNotes AS [Present position]
,revenue_and_disb_estimate_net_of_vat AS [Fees estimate]
,FeesBilledToDate AS [Fees billed to date]
,wip AS [Unbilled WIP]
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE	 'Closed' END AS [FileStatus]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN MS_Prod.config.dbFile
 ON ms_fileid=fileID
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
 WHERE  client_group_code='00000273'

 END 
GO
