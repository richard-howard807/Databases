SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ReserveChangesDisputeMatters]

AS 

BEGIN

SELECT ms_fileid
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,ISNULL(CASE WHEN client_group_name='' THEN NULL ELSE client_group_name END,client_name)  AS [Client group (or client no group)]
,name AS [Matter owner]
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,work_type_name AS [Matter type]
,referral_reason AS [Referral reason]
,[dim_detail_core_details].[present_position] AS [Present position]
,fact_finance_summary.[damages_reserve] AS [Current Damages Reserve (Latest)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Current Claimants Cost Reserve (Latest)]
,fact_finance_summary.tp_costs_reserve
,DamageReserve.NoChanges AS [Number of time current damages reserve has changed from file opening]
,ClaimantsCostReserve.NoChanges AS [Number of time current claimant costs reserve has changed from file opening]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number



INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT x.fileid, COUNT(1) AS [NoChanges]
FROM (
  SELECT fileid, curdamrescur, dss_version, ISNULL(LAG(curdamrescur) OVER (PARTITION BY ds_sh_ms_udmicurrentreserves_history.fileid ORDER BY ds_sh_ms_udmicurrentreserves_history.dss_version), 0) curDamResCur_lag
  FROM red_dw.dbo.ds_sh_ms_udmicurrentreserves_history

  ) x
WHERE curdamrescur <> x.curdamrescur_lag
GROUP BY x.fileid
) AS DamageReserve
 ON ms_fileid=DamageReserve.fileid

 LEFT OUTER JOIN (SELECT x.fileid, COUNT(1) AS [NoChanges]
FROM (
  SELECT fileid, curclacostrecur, dss_version, ISNULL(LAG(curclacostrecur) OVER (PARTITION BY ds_sh_ms_udmicurrentreserves_history.fileid ORDER BY ds_sh_ms_udmicurrentreserves_history.dss_version), 0) curclacostrecur_lag
  FROM red_dw.dbo.ds_sh_ms_udmicurrentreserves_history

  ) x
WHERE curclacostrecur <> x.curclacostrecur_lag
GROUP BY x.fileid
) AS ClaimantsCostReserve
 ON ms_fileid=ClaimantsCostReserve.fileid
 


WHERE date_opened_case_management>='2019-05-01'
AND UPPER(referral_reason) LIKE '%DISPUTE%'


ORDER BY date_opened_case_management ASC
END

GO
