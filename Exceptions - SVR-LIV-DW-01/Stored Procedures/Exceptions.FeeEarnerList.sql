SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Exceptions].[FeeEarnerList](
	  @DatasetID VARCHAR(100) = ''  
)
AS
BEGIN
	-- testing purposes	
	--Declare @DatasetID varchar(100) = '60'
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF OBJECT_ID('tempdb..#structure1') IS NOT NULL DROP TABLE #structure1
	IF OBJECT_ID('tempdb..#datasets') IS NOT NULL DROP TABLE #datasets

	CREATE TABLE #structure1(FeeEarnerCode VARCHAR(4) PRIMARY KEY, FeeEarnerName VARCHAR(81) NOT NULL, Team VARCHAR(50) NOT NULL, PracticeArea VARCHAR(50) NOT NULL)
	CREATE TABLE #datasets(DatasetID INT PRIMARY KEY)
	
	INSERT INTO #structure1 SELECT  DISTINCT RTRIM(Structure.fed_code), Structure.name, Structure.hierarchylevel4 ,Structure.hierarchylevel3
						   FROM red_dw.dbo.dim_fed_hierarchy_history  Structure
						   WHERE isnull(Structure.hierarchylevel4,'') != '' and dss_current_flag = 'Y'
						   AND LEN(Structure.fed_code) <= 4
						   AND UPPER(ISNULL(Structure.fed_code,'')) NOT IN ('','BFY', 'DKI', 'MAC','MWK','NADE','JSO','JBRO','MB1','FAL','KWA')
						   
	IF @DatasetID = ''
		INSERT INTO #datasets SELECT datasetid FROM red_dw.dbo.ds_sh_exceptions_datasets
	ELSE
		INSERT INTO #datasets SELECT part AS DatasetID FROM Exceptions.[Reporting].[ufnSplitDelimitedString](@DatasetID, ',')
	
	;WITH exceptioncases AS (
		SELECT case_id
		FROM red_dw.dbo.fact_exceptions_update AS sd
		INNER JOIN #datasets AS datasets ON sd.datasetid = datasets.DatasetID
		--WHERE DatasetID IN (SELECT DatasetID FROM #datasets) OR @DatasetID = ''
	)
	SELECT DISTINCT structure.*
				, structure.FeeEarnerName + ' [' + structure.feeearnercode + ']' AS FeeEarnerNameTag
	FROM red_dw.dbo.ds_sh_axxia_cashdr cashdr
	inner join red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON cashdr.client = camatgrp.mg_client AND cashdr.matter = camatgrp.mg_matter AND camatgrp.current_flag = 'Y'
	left outer join #structure1 AS structure ON camatgrp.mg_feearn = structure.FeeEarnerCode COLLATE Latin1_General_BIN
	WHERE cashdr.case_id IN (SELECT case_id FROM exceptioncases) and cashdr.current_flag = 'Y' order by structure.feeearnercode
END
GO
