SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Exceptions].[FeeEarnerListDWH] (
	  @DatasetID VARCHAR(max) = ''  
)
AS
BEGIN
	-- testing purposes	
	--Declare @DatasetID varchar(100) = '60'
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF OBJECT_ID('tempdb..#datasets') IS NOT NULL DROP TABLE #datasets

	CREATE TABLE #datasets(DatasetID INT PRIMARY KEY)
	

	IF @DatasetID = ''
		INSERT INTO #datasets SELECT datasetid FROM red_dw.dbo.ds_sh_exceptions_datasets WHERE mattersphere = 1
	ELSE
		INSERT INTO #datasets SELECT part AS DatasetID FROM Exceptions.[Reporting].[ufnSplitDelimitedString](@DatasetID, ',')
	
		SELECT DISTINCT dfh.fed_code, dfh.name FROM red_Dw.dbo.fact_exceptions_update feu
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history dfh ON feu.fed_code = dfh.fed_code AND dfh.dss_current_flag = 'Y' AND dfh.activeud = 1
		inner JOIN #datasets  datasettable ON feu.datasetid   = datasettable.DatasetID 
		ORDER BY name
END
GO
