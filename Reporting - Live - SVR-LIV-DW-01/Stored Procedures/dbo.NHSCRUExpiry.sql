SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NHSCRUExpiry]
(
 @StartDate AS DATE
,@EndDate AS DATE
,@Team AS NVARCHAR(MAX)
,@FeeEarner AS NVARCHAR(MAX)
)
AS

		IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
		SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
		
		IF OBJECT_ID('tempdb..#FE') IS NOT NULL   DROP TABLE FE
		SELECT ListValue  INTO #FE FROM 	dbo.udt_TallySplit(',', @FeeEarner)
		

BEGIN 

SELECT master_client_code +'-'+ master_matter_number AS [MSReference]
,matter_owner_full_name AS [Matter Owner]
,RTRIM(dim_claimant_thirdparty_involvement.claimant_name) AS [Claimant name]
,hierarchylevel4hist AS [Team]
,RTRIM(CRUREf.assocRef) AS CRUReference
,tskDesc AS [CRU certificate expiry Desc]
,tskDue AS [CRU certificate expiry date]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #FE AS FE ON FE.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
INNER JOIN ms_prod.dbo.dbTasks
 ON fileID=ms_fileid
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
 LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_claimant_thirdparty_involvement.client_code 
 AND dim_detail_outcome.matter_number = dim_claimant_thirdparty_involvement.matter_number
 
LEFT OUTER JOIN (SELECT fileID,assocRef FROM MS_Prod.config.dbAssociates
WHERE assocType='COMPRECUNITDWP'
AND assocRef IS NOT NULL) AS CRUREf
 ON ms_fileid=CRUREf.fileID
WHERE master_client_code='N1001'
AND date_closed_practice_management IS NULL
AND tskDesc LIKE '%CRU Expiry due - today%'
AND tskActive=1
AND tskCompleted IS NULL
AND dim_detail_outcome.date_claim_concluded IS NULL 

AND CONVERT(DATE,tskDue,103) BETWEEN @StartDate AND @EndDate

END
GO
