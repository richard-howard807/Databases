SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 21/02/2018
-- Description:	Webby Ticket 295245 (Based on the Fraud Indicator Score report)
-- =============================================
-- ES 2020-03-12 42547 Amended the logic to look at the FIC Process task rather than
--						filter based on the FIC score which is based on case details
-- ES 2020-06-09 58589 Removed fixed fee from total calc
-- ES 2020-09-15 amended logic to look at the history of the date the score was inserted if there is no task information as the task has been deleted on the frontend, requested by Mandy Hudson
-- ES 2020-09-15 added client group name parameter requested by Bob H
-- ES 2020-09-18 amended fic logic to look at quetsions as the tasks show as completed if the process was cancelled
-- ES 2021-01-12 removed leavers, #84433
-- ES 2021-01-20 removed work type  1603, PL - Pol - CHIS, requested by BH
--==============================================
CREATE  PROCEDURE [fraud].[fic_results_report_test] 

(
    @FedCode AS VARCHAR(MAX),
    --@Month AS VARCHAR(100)
    @Level AS VARCHAR(100)
	,@Status AS VARCHAR(MAX)
	,@ClientGroupName VARCHAR(MAX)
)
	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED




IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL   DROP TABLE #FICProcess

	DROP TABLE  IF EXISTS #FedCodeList
    	CREATE TABLE #FedCodeList  (
ListValue  NVARCHAR(MAX)
)

IF OBJECT_ID('tempdb..#ClientGroupName') IS NOT NULL   DROP TABLE #ClientGroupName

IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status

IF @level  <> 'Individual'
	BEGIN
	PRINT ('not Individual')
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
use red_dw;
DECLARE @nDate AS DATE = GETDATE()

SELECT DISTINCT
dim_fed_hierarchy_history_key
FROM red_Dw.dbo.dim_fed_hierarchy_history 
WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

INSERT INTO #FedCodeList 
EXEC sp_executesql @sql
	END
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT INTO #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END

	



	--SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)
	--SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
	--SELECT ListValue  INTO #Handler FROM 	dbo.udt_TallySplit(',', @Handler)
	--SELECT ListValue  INTO #ClientGroupName FROM 	dbo.udt_TallySplit(',', @ClientGroupName)


	--SELECT fileID, tskDesc, tskDue, tskCompleted 
	--INTO #FICProcess
	--FROM MS_Prod.dbo.dbTasks
	--WHERE (tskDesc LIKE 'FIC Process'
	--OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
	--AND tskActive=1


	SELECT Process.fileid
	, Process.totalpointscalc
	, Process.Completed
	, CASE WHEN Process.Completed=1 THEN tskDesc ELSE NULL END AS [tskDesc]
	, CASE WHEN Process.Completed=1 THEN tskDue ELSE NULL END AS [tskDue]
	, CASE WHEN Process.Completed=1 THEN tskCompleted ELSE NULL END AS [tskCompleted]
	INTO #FICProcess
FROM (
	SELECT ds_sh_ms_udficmotor.fileid
	, ds_sh_ms_udficcommon.totalpointscalc
	, CASE WHEN ds_sh_ms_udficmotor.cbomotorintelty IS NOT NULL 
		OR ds_sh_ms_udficmotor.cbonoofoccupant IS NOT NULL
        OR ds_sh_ms_udficmotor.cbomultiaccid IS NOT NULL
        OR ds_sh_ms_udficmotor.cboothpartyconc IS NOT NULL
        OR ds_sh_ms_udficmotor.cboinconsistdmg IS NOT NULL
        OR ds_sh_ms_udficmotor.cbomultioccupan IS NOT NULL
        OR ds_sh_ms_udficmotor.cbovagueadmit IS NOT NULL
        OR ds_sh_ms_udficmotor.cbofailureassis IS NOT NULL
        OR ds_sh_ms_udficmotor.cbohighriskunem IS NOT NULL
        OR ds_sh_ms_udficmotor.cbolateearlyacc IS NOT NULL
        OR ds_sh_ms_udficmotor.cbophantomtp IS NOT NULL
        OR ds_sh_ms_udficmotor.cbounustpbehaiv IS NOT NULL
        OR ds_sh_ms_udficmotor.cboaccmancomp IS NOT NULL
        OR ds_sh_ms_udficmotor.cbolowvalue IS NOT NULL 
		OR ds_sh_ms_udficdisease.cboprevsamedise IS NOT NULL
        OR ds_sh_ms_udficdisease.cbountruestatem IS NOT NULL
        OR ds_sh_ms_udficdisease.cboincorrectpor IS NOT NULL
        OR ds_sh_ms_udficdisease.cbomulticachecr IS NOT NULL
        OR ds_sh_ms_udficdisease.cboirisothersol IS NOT NULL
        OR ds_sh_ms_udficdisease.cbo20yrslastexp IS NOT NULL
        OR ds_sh_ms_udficdisease.cboprevothdisea IS NOT NULL
        OR ds_sh_ms_udficdisease.cbo1stclaimdef IS NOT NULL
        OR ds_sh_ms_udficdisease.cboworklocdisp IS NOT NULL
        OR ds_sh_ms_udficdisease.cbonowitnesses IS NOT NULL
        OR ds_sh_ms_udficdisease.cbonolongertrad IS NOT NULL
        or ds_sh_ms_udficdisease.cboposdefnopers IS NOT NULL
        OR ds_sh_ms_udficdisease.txthandlerfeel IS NOT NULL
		OR ds_sh_ms_udficdisease.cbonoretdeclar IS NOT NULL
        OR ds_sh_ms_udficdisease.cbofailclarific IS NOT NULL
        OR ds_sh_ms_udficdisease.cbomedrecrefus IS NOT NULL
        OR ds_sh_ms_udficdisease.cboothinvestref IS NOT NULL
        OR ds_sh_ms_udficdisease.cbocontraalleg IS NOT NULL
        OR ds_sh_ms_udficdisease.cbotipoff IS NOT NULL
        OR ds_sh_ms_udficdisease.cboprevconv IS NOT NULL
		OR ds_sh_ms_udficdisease.cboproblemempl IS NOT NULL 
		OR ds_sh_ms_udficdisease.cbowrongtruemul IS NOT NULL
        OR ds_sh_ms_udficdisease.cboallsurv IS NOT NULL
        OR ds_sh_ms_udficdisease.cbofabrheadloss IS NOT NULL
        OR ds_sh_ms_udficdisease.cboexagheadloss IS NOT NULL
        OR ds_sh_ms_udficdisease.cbomednotconsis IS NOT NULL
        OR ds_sh_ms_udficdisease.cboevidinconsis IS NOT NULL
        OR ds_sh_ms_udficdisease.cbonoidexam IS NOT NULL
        OR ds_sh_ms_udficdisease.cboothexcclaim IS NOT NULL
        OR ds_sh_ms_udficdisease.cbogprecsnorev IS NOT NULL
        OR ds_sh_ms_udficdisease.cbonoassesaahl IS NOT NULL
        OR ds_sh_ms_udficdisease.cbonoasscentile IS NOT NULL
        OR ds_sh_ms_udficdisease.cbogprecnotinn IS NOT NULL
        OR ds_sh_ms_udficdisease.cbohearless25 IS NOT NULL 
		OR ds_sh_ms_udficelpl.cbotipofffraud IS NOT NULL
        OR ds_sh_ms_udficelpl.cbodisgruntempl IS NOT NULL
        OR ds_sh_ms_udficelpl.cboprevhistory IS NOT NULL
        OR ds_sh_ms_udficelpl.cboinconsistcla IS NOT NULL
        OR ds_sh_ms_udficelpl.cboearlysetofr IS NOT NULL
        OR ds_sh_ms_udficelpl.cbopersonalpres IS NOT NULL
        OR ds_sh_ms_udficelpl.cborefusecoop IS NOT NULL
        OR ds_sh_ms_udficelpl.cboageabilincon IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowitownagenda IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowituncoop IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowitfraudlink IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowitnessincon IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowitrefusesig IS NOT NULL
        OR ds_sh_ms_udficelpl.cboaccidentrep IS NOT NULL
        OR ds_sh_ms_udficelpl.cbocircsinconsi IS NOT NULL
        OR ds_sh_ms_udficelpl.cbonowitnesses IS NOT NULL
        OR ds_sh_ms_udficelpl.cbowitnessevid IS NOT NULL
        OR ds_sh_ms_udficelpl.cbosimilclaims IS NOT NULL
        OR ds_sh_ms_udficelpl.cbounusualinjur IS NOT NULL
        OR ds_sh_ms_udficelpl.cboinjuryincon IS NOT NULL
        OR ds_sh_ms_udficelpl.cbogpattenddel IS NOT NULL
        OR ds_sh_ms_udficelpl.cbotimeoffwork IS NOT NULL
        OR ds_sh_ms_udficelpl.cbolackofevid IS NOT NULL
        OR ds_sh_ms_udficelpl.cboexagclaim IS NOT NULL
        OR ds_sh_ms_udficelpl.cbofabheadloss IS NOT NULL 
		THEN 1 ELSE 0 END AS [Completed]

	FROM red_dw.dbo.ds_sh_ms_udficcommon
	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficmotor
	ON ds_sh_ms_udficmotor.fileid = ds_sh_ms_udficcommon.fileid
	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficdisease
	ON ds_sh_ms_udficdisease.fileid = ds_sh_ms_udficcommon.fileid
	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficelpl
	ON ds_sh_ms_udficelpl.fileid = ds_sh_ms_udficcommon.fileid
	) AS [Process]
	LEFT OUTER JOIN (SELECT fileID, tskDesc, tskDue, tskCompleted 
					FROM MS_Prod.dbo.dbTasks
					WHERE (tskDesc LIKE '%FIC Process%'
					OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
					AND tskActive=1) AS [Tasks] ON Tasks.fileID = Process.fileid

	SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit(',', @Status)

		CREATE TABLE #ClientGroupName 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #ClientGroupName
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @ClientGroupName) 
	
	 SELECT 
		 [Client Code] = dim_matter_header_current.client_code
		 ,[Matter Number]=dim_matter_header_current.matter_number
		 ,[Date Opened] = dim_matter_header_current.date_opened_case_management
		 ,[Matter Description]=dim_matter_header_current.matter_description
		 ,dim_matter_header_current.matter_owner_full_name
		 ,dim_fed_hierarchy_history.hierarchylevel2hist AS Area 
		 ,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
		 ,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
		 ,dim_detail_core_details.suspicion_of_fraud
		 ,referral_reason AS [Referral Reason]
		 ,CASE WHEN date_closed_case_management IS NULL THEN DATEDIFF(DAY, date_opened_case_management,GETDATE())
					ELSE DATEDIFF(DAY,date_opened_case_management, date_closed_case_management) END AS [Days Opened]
					,dim_fed_hierarchy_history.name [FeeEarnerName]

		 ,fic =	 FICProcess.totalpointscalc

		 ,fic_fraud_transfer_date [fic_review_date]
		 ,fic_fraud_transfer [fic_revew]
		 ,date_received 
		 ,date_intel_report_sent
		 ,FICProcess.tskDue
		 ,(CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) AS [tskCompleted]
		 ,CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskDesc IS NULL THEN 'FIC Process' ELSE FICProcess.tskDesc END AS [tskDesc]
		 ,ms_fileid
		 ,work_type_group
		 ,CASE WHEN (client_group_name IS NULL OR client_group_name='') THEN  client_name ELSE client_group_name END AS [Client Group Name]
		 		,dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		,ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount]
		,RTRIM(ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0)) AS [Fee Arrangement]
		,fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		,CASE WHEN FICProcess.tskDue IS NULL AND FICProcess.totalpointscalc IS NULL THEN 1 ELSE 0 END AS [CountNoprocessdue]
	  
		,CASE WHEN FICProcess.tskDue IS NOT NULL AND (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NULL THEN 1 ELSE 0 END AS [countcompleteddate]
		,CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NOT NULL AND FICProcess.totalpointscalc IS NULL THEN 1 ELSE 0 END AS [countblankscore]
		,CASE WHEN  FICProcess.totalpointscalc < 15 THEN 1 ELSE 0 END AS [countless15]
		,CASE WHEN  FICProcess.totalpointscalc >= 15 THEN 1 ELSE 0 END AS [countmore15]
	
		, CASE WHEN (dim_matter_header_current.fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee ' AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0  ) OR (ISNULL(fact_finance_summary.defence_costs_reserve,0) = 0 ) THEN 1 ELSE 0
		END AS [countfixeddefence]
		, CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NULL AND FICProcess.totalpointscalc IS NOT NULL THEN 1 ELSE 0 END AS [countscorenotcompleted]
----------------------------
 	,(CASE WHEN FICProcess.tskDue IS NULL THEN 1 ELSE 0 END +
	CASE WHEN FICProcess.tskDue IS NOT NULL AND (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NULL THEN 1 ELSE 0 END + 
		CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NOT NULL AND FICProcess.totalpointscalc IS NULL THEN 1 ELSE 0 END +
		CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NOT NULL AND FICProcess.totalpointscalc < 15 THEN 1 ELSE 0 END +
		CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NOT NULL AND FICProcess.totalpointscalc > 15 THEN 1 ELSE 0 END) -
		CASE WHEN (CASE WHEN FICProcess.totalpointscalc>=0 AND FICProcess.tskCompleted IS NULL THEN ScoreDate.dss_start_date ELSE FICProcess.tskCompleted END) IS NULL AND FICProcess.totalpointscalc IS NOT NULL THEN 1 ELSE 0 END
		--CASE WHEN (dim_matter_header_current.fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee ' AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0  ) OR (ISNULL(fact_finance_summary.defence_costs_reserve,0) = 0 ) THEN 1 ELSE 0
		--END 
		AS TOTAL 
	,  CASE WHEN 
		--dim_matter_header_current.date_closed_case_management IS NULL
	   dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		--AND dim_detail_outcome.date_claim_concluded IS NULL
		AND LOWER(referral_reason) LIKE '%dispute%'
		AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease') 
		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR FICProcess.totalpointscalc IS NOT NULL)
		THEN 1 ELSE 0 END AS [Number of Matters]
		, CASE WHEN FICProcess.totalpointscalc IS NOT NULL THEN 1 ELSE 0 END AS [countscore]
		, CASE WHEN date_claim_concluded IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]

	FROM 
	red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key  
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'        
	AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
	AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
	AND leaver=0
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw..dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
	LEFT OUTER JOIN red_dw..dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

	--LEFT OUTER JOIN (SELECT fileID, tskDesc, tskCompleted 
	--			FROM MS_Prod.dbo.dbTasks
	--			WHERE tskDesc LIKE 'FIC Process'
	--			AND tskCompleted IS NOT NULL 
	--			AND tskActive=1) AS FICProcess ON FICProcess.fileID=ms_fileid


	--INNER JOIN #Department AS Department ON Department.ListValue = hierarchylevel3hist 
	--INNER JOIN #Team AS Team ON Team.ListValue = hierarchylevel4hist 
	--INNER JOIN #Handler AS Handler ON Handler.ListValue = matter_owner_full_name 
	INNER JOIN #ClientGroupName AS ClientGroupName ON ClientGroupName.ListValue = CASE WHEN (client_group_name IS NULL OR client_group_name='') THEN  client_name ELSE client_group_name END 
	
	LEFT OUTER JOIN (SELECT totalpointscalc, ds_sh_ms_udficcommon_history.dss_start_date, ds_sh_ms_udficcommon_history.dss_end_date, ds_sh_ms_udficcommon_history.fileid
					FROM red_dw.dbo.ds_sh_ms_udficcommon_history
					WHERE ds_sh_ms_udficcommon_history.dss_current_flag='Y') AS [ScoreDate] ON [ScoreDate].fileid=dim_matter_header_current.ms_fileid

--	LEFT OUTER JOIN (
--	SELECT Process.fileid
--	, Process.totalpointscalc
--	, Process.Completed
--	, CASE WHEN Process.Completed=1 THEN tskDesc ELSE NULL END AS [tskDesc]
--	, CASE WHEN Process.Completed=1 THEN tskDue ELSE NULL END AS [tskDue]
--	, CASE WHEN Process.Completed=1 THEN tskCompleted ELSE NULL END AS [tskCompleted]
--FROM (
--	SELECT ds_sh_ms_udficmotor.fileid
--	, ds_sh_ms_udficcommon.totalpointscalc
--	, CASE WHEN ds_sh_ms_udficmotor.cbomotorintelty IS NOT NULL 
--		OR ds_sh_ms_udficmotor.cbonoofoccupant IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbomultiaccid IS NOT NULL
--        OR ds_sh_ms_udficmotor.cboothpartyconc IS NOT NULL
--        OR ds_sh_ms_udficmotor.cboinconsistdmg IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbomultioccupan IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbovagueadmit IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbofailureassis IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbohighriskunem IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbolateearlyacc IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbophantomtp IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbounustpbehaiv IS NOT NULL
--        OR ds_sh_ms_udficmotor.cboaccmancomp IS NOT NULL
--        OR ds_sh_ms_udficmotor.cbolowvalue IS NOT NULL 
--		OR ds_sh_ms_udficdisease.cboprevsamedise IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbountruestatem IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboincorrectpor IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbomulticachecr IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboirisothersol IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbo20yrslastexp IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboprevothdisea IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbo1stclaimdef IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboworklocdisp IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbonowitnesses IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbonolongertrad IS NOT NULL
--        or ds_sh_ms_udficdisease.cboposdefnopers IS NOT NULL
--        OR ds_sh_ms_udficdisease.txthandlerfeel IS NOT NULL
--		OR ds_sh_ms_udficdisease.cbonoretdeclar IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbofailclarific IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbomedrecrefus IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboothinvestref IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbocontraalleg IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbotipoff IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboprevconv IS NOT NULL
--		OR ds_sh_ms_udficdisease.cboproblemempl IS NOT NULL 
--		OR ds_sh_ms_udficdisease.cbowrongtruemul IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboallsurv IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbofabrheadloss IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboexagheadloss IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbomednotconsis IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboevidinconsis IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbonoidexam IS NOT NULL
--        OR ds_sh_ms_udficdisease.cboothexcclaim IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbogprecsnorev IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbonoassesaahl IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbonoasscentile IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbogprecnotinn IS NOT NULL
--        OR ds_sh_ms_udficdisease.cbohearless25 IS NOT NULL 
--		OR ds_sh_ms_udficelpl.cbotipofffraud IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbodisgruntempl IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboprevhistory IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboinconsistcla IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboearlysetofr IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbopersonalpres IS NOT NULL
--        OR ds_sh_ms_udficelpl.cborefusecoop IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboageabilincon IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowitownagenda IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowituncoop IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowitfraudlink IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowitnessincon IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowitrefusesig IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboaccidentrep IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbocircsinconsi IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbonowitnesses IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbowitnessevid IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbosimilclaims IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbounusualinjur IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboinjuryincon IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbogpattenddel IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbotimeoffwork IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbolackofevid IS NOT NULL
--        OR ds_sh_ms_udficelpl.cboexagclaim IS NOT NULL
--        OR ds_sh_ms_udficelpl.cbofabheadloss IS NOT NULL 
--		THEN 1 ELSE 0 END AS [Completed]

--	FROM red_dw.dbo.ds_sh_ms_udficcommon
--	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficmotor
--	ON ds_sh_ms_udficmotor.fileid = ds_sh_ms_udficcommon.fileid
--	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficdisease
--	ON ds_sh_ms_udficdisease.fileid = ds_sh_ms_udficcommon.fileid
--	LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficelpl
--	ON ds_sh_ms_udficelpl.fileid = ds_sh_ms_udficcommon.fileid
--	) AS [Process]
--	LEFT OUTER JOIN (SELECT fileID, tskDesc, tskDue, tskCompleted 
--					FROM MS_Prod.dbo.dbTasks
--					WHERE (tskDesc LIKE 'FIC Process'
--					OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
--					AND tskActive=1) AS Task ON Task.fileID = [Process].fileid
--	--WHERE fileid='5041964'
--	) AS [FICProcess] ON FICProcess.fileid = dim_matter_header_current.ms_fileid

	LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileid = ms_fileid

	INNER JOIN #Status ON #Status.ListValue = CASE WHEN date_claim_concluded IS NULL THEN 'Open' ELSE 'Closed' END

	WHERE 
	--dim_matter_header_current.date_closed_case_management IS NULL
		 dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
	--AND dim_detail_outcome.date_claim_concluded IS NULL

		AND LOWER(referral_reason) LIKE '%dispute%'
	AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease')

		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR FICProcess.totalpointscalc IS NOT NULL)
		AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case,''))<>'exclude from reports'
		AND ISNULL(dim_matter_worktype.work_type_code,'')<>'1603'

 AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
              (
                  SELECT (CASE
                              WHEN @Level = 'Firm' THEN
                                  dim_fed_hierarchy_history_key
                              ELSE
                                  0
                          END
                         )
                  FROM red_dw.dbo.dim_fed_hierarchy_history
                  UNION
                  SELECT  (CASE
                              WHEN @Level IN ( 'Individual' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
                  UNION
                  SELECT (CASE
                              WHEN @Level IN ( 'Area Managed' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
              )

			  
END;




--SELECT fileID, tskDesc, tskCompleted,*
--				FROM MS_Prod.dbo.dbTasks
--				WHERE tskDesc LIKE 'FIC Process'
--				AND tskActive=1
GO
