SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ASWatsonDisbursementsOld]
AS
BEGIN

SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'Superdrug - General Disbursements' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787558' AND matter='00000001'

UNION ALL

	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'Superdrug - SDLT' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787558' AND matter='00000002'
UNION ALL
	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'The Perfume Shop Limited - General Disbursements' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787559' AND matter='00000001'

UNION ALL

	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'The Perfume Shop Limited - SDLT' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787559' AND matter='00000002'
UNION ALL
	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'3 - General Disbursements' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787560' AND matter='00000001'

UNION ALL

	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'3 - SDLT' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787560' AND matter='00000002'
UNION ALL
	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,CASE WHEN narrative='<style type="text/css">  p { margin-top: 0px;margin-bottom: 0px;line-height: 1; }   body { font-family: ''Verdana'';font-style: Normal;font-weight: normal;font-size: 10.66666px;color: #000000; }   .p_A203A582 { margin-top: 0px;margin-bottom: 0px;line-height: 1; }   .s_C3233D33 { font-family: ''Verdana'';font-style: Normal;font-weight: normal;font-size: 10.66666px;color: #000000; } </style><p class="p_A203A582"><span class="s_C3233D33">Transfer from 787561.01 to&nbsp; 787861.132 Landlords solicitors fees</span><span class="s_C3233D33"></span></p>' THEN 'Transfer from 787561.01 to  787861.132 Landlords solicitors fees' ELSE narrative END  [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'Savers - General Disbursements' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787561' AND matter='00000001'

UNION ALL

	SELECT client AS Client
	,matter AS Matter
	,post_date AS [Date]
	,narrative [Description]

	,CASE WHEN amount > 0 THEN amount ELSE NULL END AS [Money In]
	,CASE WHEN amount < 0 THEN amount ELSE NULL END AS [Money Out]--,* 
	,NULL AS Ref
	,NULL AS [ASW Property Contact]
	,'Savers - SDLT' AS Area
	,amount AS amount
	FROM converge.vw_replicated_trust_balance
WHERE client='00787561' AND matter='00000002'


END 
GO
