SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NHSRCostBillingRequests]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 
BEGIN

SELECT RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [Client/matter - MS]
,name AS [Matter owner]
,hierarchylevel4hist AS [Team]
,insurerclient_name AS [Insurer client reference]
,CASE WHEN cboCostBilled='Y' THEN 'Yes' WHEN cboCostBilled='N' THEN 'No' ELSE cboCostBilled END AS [All WIP is CB coded]
,CostBillType.cdDesc AS [Type of Cost bill required]
,CBStage.cdDesc AS [Stage]
,curFee AS [Fee]
,txtNotes AS [Billing Notes]
,red_dw.dbo.datetimelocal(dteInserted) AS [Activity date]
,usrFullName AS  [Who ran the activity?]
,a.cboBillType
,CostBillType.cdDesc
,a.*
FROM MS_Prod.dbo.udNHSRBillProcessSL AS a WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=a.fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN ms_prod.dbo.dbUser WITH(NOLOCK)
 ON usrID=usrIDInserted
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS CostBillType WITH(NOLOCK)
 ON a.cboBillType=CostBillType.cdCode AND CostBillType.cdType='NHSRBILLTYPE'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS CBStage WITH(NOLOCK)
 ON a.cboCBStage=CBStage.cdCode AND CBStage.cdType='CBSTAGE'
WHERE CostBillType.cdDesc='Cost Bill'
AND master_client_code='N1001'
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dteInserted),103) BETWEEN @StartDate AND @EndDate
END 
GO
