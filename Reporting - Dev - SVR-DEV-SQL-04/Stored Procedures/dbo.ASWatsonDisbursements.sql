SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ASWatsonDisbursements]


	@StartDate DATE
	,@EndDate DATE

AS

BEGIN


IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results

    -- For Testing Purposes
	--DECLARE @StartDate Datetime
	--DECLARE @EndDate Datetime
	--SET @StartDate = '20170101'
	--SET @EndDate = '20170727'

SELECT * INTO #Results 
FROM (

SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'Superdrug - General Disbursements' AS Area
       ,amount AS amount
	   ,SUM(amount) OVER (ORDER BY post_date,sequence_number  ROWS UNBOUNDED PRECEDING) AS [Running Total]
  

       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787558-1'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787558' AND vw_replicated_trust_balance.matter='00000001'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'Superdrug - SDLT' AS Area
       ,amount AS amount    
	   ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total]  


       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787558-2'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787558' AND vw_replicated_trust_balance.matter='00000002'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'The Perfume Shop Limited - General Disbursements' AS Area
       ,amount AS amount
 ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total]

       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787559-1'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787559' AND vw_replicated_trust_balance.matter='00000001'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'The Perfume Shop Limited - SDLT' AS Area
       ,amount AS amount
       ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total] 


       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787559-2'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787559' AND vw_replicated_trust_balance.matter='00000002'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'3 - General Disbursements' AS Area
       ,amount AS amount
        ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total]


       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787560-1'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact 
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787560' AND vw_replicated_trust_balance.matter='00000001'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'3 - SDLT' AS Area
       ,amount AS amount
        ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total]


       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787560-2'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787560' AND vw_replicated_trust_balance.matter='00000002'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       --,CASE WHEN ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments)='<style type="text/css">  p { margin-top: 0px;margin-bottom: 0px;line-height: 1; }   body { font-family: ''Verdana'';font-style: Normal;font-weight: normal;font-size: 10.66666px;color: #000000; }   .p_A203A582 { margin-top: 0px;margin-bottom: 0px;line-height: 1; }   .s_C3233D33 { font-family: ''Verdana'';font-style: Normal;font-weight: normal;font-size: 10.66666px;color: #000000; } </style><p class="p_A203A582"><span class="s_C3233D33">Transfer from 787561.01 to&nbsp; 787861.132 Landlords solicitors fees</span><span class="s_C3233D33"></span></p>' THEN 'Transfer from 787561.01 to  787861.132 Landlords solicitors fees' ELSE ISNULL(vw_replicated_trust_balance.narrative,TransferTo.Comments) END  [Description]
	   ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments)  [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'Savers - General Disbursements' AS Area
       ,amount AS amount
	   ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total]

       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787561-1'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787561' AND vw_replicated_trust_balance.matter='00000001'
UNION ALL
SELECT vw_replicated_trust_balance.client AS Client
       ,vw_replicated_trust_balance.matter AS Matter
       ,post_date AS [Date]
       ,ISNULL(vw_replicated_trust_balance.narrativeunformated,TransferTo.Comments) [Description]
	    , sequence_number
       ,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
       ,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
       ,TransferTo.client + '.' + TransferTo.matter AS Ref
       ,property_contact AS [ASW Property Contact]
       ,'Savers - SDLT' AS Area
       ,amount AS amount
       ,SUM(amount) OVER (ORDER BY post_date, sequence_number ROWS UNBOUNDED PRECEDING) AS [Running Total] 


       FROM converge.vw_replicated_trust_balance
       LEFT JOIN (SELECT vw_replicated_trust_balance.TrustTransfer,[client],matter,TrustTransfer.Comments
FROM converge.vw_replicated_trust_balance 
INNER JOIN (SELECT TrustTransfer,TrustTransferDetail.Comments
FROM TE_3E_PROD.dbo.TrustBalance
INNER JOIN TE_3E_PROD.dbo.Matter ON Matter.MattIndex = TrustBalance.Matter AND Matter.Number = '787561-2'
LEFT JOIN  TE_3E_PROD.dbo.TrustTransferDetail ON TrustTransferDetail.TrustTransferDetIndex = TrustBalance.TrustTransferDetail
WHERE 
PostSource ='TRSTTRSF') TrustTransfer ON vw_replicated_trust_balance.TrustTransfer = TrustTransfer.TrustTransfer
WHERE IsSource = 0) TransferTo ON vw_replicated_trust_balance.TrustTransfer = TransferTo.TrustTransfer
LEFT OUTER JOIN
(
SELECT a.client_code,a.matter_number,property_contact FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON fact_dimension_main.dim_detail_property_key=dim_detail_property.dim_detail_property_key
WHERE property_contact IS NOT NULL
) AS PropertyContact
ON TransferTo.client=PropertyContact.client_code  collate database_default
AND TransferTo.matter=PropertyContact.matter_number collate database_default
WHERE vw_replicated_trust_balance.client='00787561' AND vw_replicated_trust_balance.matter='00000002'
) AS AllData




SELECT * FROM #Results
WHERE [Date] BETWEEN @StartDate AND @EndDate
ORDER BY [Date] DESC,[Running Total] asc



END 
GO
