SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		ste G
-- Create date: 11/01/2017
-- Description: Zurich Re-opened Cases Report for Magdalena Wloka   (Webby 285258 )
-- =============================================


create PROCEDURE [zurich].[ReOpenedCasesReportOld]
	
	@StartDate DATE
	,@EndDate DATE
AS
BEGIN
	
	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    -- For Testing Purposes
	--DECLARE @StartDate Datetime
	--DECLARE @EndDate Datetime
	--SET @StartDate = '20160701'
	--SET @EndDate = '20160727'


SELECT 
		cashdr.case_id
		, 'Weightmans'		[Panel Firm]
		, WPS275.case_text	[Zurich Reference]
		, RTRIM(cashdr.client) + '.' + CAST(CAST(cashdr.matter AS INT)AS VARCHAR) [Panel Ref]
		, dim_client_involvement.insuredclient_name   [Insured]
		, reporting.dbo.ufn_Coalesce_CapacityDetails_nameonly(cashdr.case_id, '~ZCLAIM') [Claimant Name]
		, TRA094.case_date			[Date Instructed] 
		, TRA086.case_date			[Date Settled]
		, VE00896.case_text			[Reason fo Settlement]
		, VE00897.case_text			[Reason for Reopening Request]
		, WPS277.case_value			[Current Reserve]
		, ClaimStatus
		, VE00094.case_date [Reopen Date]
		,name AS [Case Handler]
	FROM red_Dw.dbo.ds_sh_axxia_cashdr cashdr
	INNER JOIN red_Dw.dbo.ds_sh_axxia_camatgrp camatgroup
		   ON cashdr.client = camatgroup.mg_client
		   AND cashdr.matter = camatgroup.mg_matter
	INNER JOIN (SELECT DISTINCT case_id FROM red_Dw.dbo.ds_sh_axxia_casdet 
	 WHERE case_detail_code = 'VE00093' and effective_start_date  BETWEEN @StartDate AND @EndDate ) StatusChange
		ON cashdr.case_id = StatusChange.case_id
	left join red_Dw.dbo.fact_dimension_main fdm on fdm.client_code = cashdr.client and matter =fdm.matter_number  
	left join red_Dw.dbo.dim_claimant_thirdparty_involvement on fdm.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
	left join red_dw.dbo.dim_client_involvement on fdm.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='TRA094' and current_flag = 'Y' and deleted_flag = 'N') AS TRA094 ON cashdr.case_id = TRA094.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='TRA068' and current_flag = 'Y' and deleted_flag = 'N') AS TRA068 ON cashdr.case_id = TRA068.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='TRA086' and current_flag = 'Y' and deleted_flag = 'N') AS TRA086 ON cashdr.case_id = TRA086.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='TRA085' and current_flag = 'Y' and deleted_flag = 'N') AS TRA085 ON cashdr.case_id = TRA085.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='WPS275' and current_flag = 'Y' and deleted_flag = 'N') AS WPS275 ON cashdr.case_id = WPS275.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='WPS277' and current_flag = 'Y' and deleted_flag = 'N') AS WPS277  ON WPS275.case_id = WPS277.case_id AND WPS275.seq_no = WPS277.cd_parent
   
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='VE00896' and current_flag = 'Y' and deleted_flag = 'N') AS VE00896 ON cashdr.case_id = VE00896.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='VE00897' and current_flag = 'Y' and deleted_flag = 'N') AS VE00897 ON cashdr.case_id = VE00897.case_id
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='VE00094' and current_flag = 'Y' and deleted_flag = 'N') AS VE00094 ON cashdr.case_id = VE00094.case_id
	LEFT OUTER JOIN red_Dw.dbo.dim_fed_hierarchy_history on mg_feearn = fed_code and dim_fed_hierarchy_history.dss_current_flag = 'Y' --and activeud = '1'
						
	LEFT OUTER JOIN	(SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet WITH (NOLOCK)	WHERE case_detail_code='NMI980' and current_flag = 'Y' and deleted_flag = 'N') AS NMI980 ON cashdr.case_id=NMI980.case_id
	
	LEFT OUTER JOIN (SELECT case_id,case_text AS ClaimStatus FROM red_Dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='VE00093' and current_flag = 'Y' and deleted_flag = 'N') AS ClaimStatusValue
	 ON cashdr.case_id=ClaimStatusValue.case_id
	--Injury and Injury Description
	LEFT OUTER JOIN (SELECT * FROM red_Dw.dbo.ds_sh_axxia_casdet (NOLOCK) WHERE case_detail_code = 'WPS027' and current_flag = 'Y' and deleted_flag = 'N') AS WPS027 ON WPS027.case_id = cashdr.case_id
		LEFT OUTER  JOIN axxia01.dbo.stdetlst InjuryDesc ON WPS027.case_text = InjuryDesc.sd_liscod AND InjuryDesc.sd_detcod = 'WPS027'

	WHERE 1=1
	and cashdr.current_flag = 'Y'
	and camatgroup.current_flag = 'Y'
	-- standard exclusions for test cases and Money Laundering matters
		AND  (cashdr.client IN ('Z00002','Z00004','Z00018','Z00014')
		OR (cashdr.client = 'Z1001' and NMI980.case_text IN ('Outsource - NIHL', 'Outsource - Coats', 'Outsource - HAVS')
		
		)
		)

		AND cashdr.matter <> 'ML'

		AND cashdr.client NOT IN ('00030645','95000C','00453737')  -- Need to exclude these clients in reports (Test clients)
		AND ISNULL(TRA068.case_text,'') <> 'Exclude from reports'	
		AND ClaimStatus = 'Re-opened'

END

GO
