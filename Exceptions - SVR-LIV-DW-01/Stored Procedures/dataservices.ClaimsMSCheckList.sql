SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 10/09/2018
-- Description:	This code was initially in the report Kevin created but I have moved to a stored procedure
--				because the parameters don't appear to work within the report although the sql is correct
--				
-- =============================================
CREATE PROCEDURE [dataservices].[ClaimsMSCheckList]
	@Department NVARCHAR(500)
	,@Team		NVARCHAR(500)
	,@FeeEarner NVARCHAR (500)
AS

	
	-- For testing purposes
	--DECLARE @Department NVARCHAR(200) = 'Casualty'
	--DECLARE @Team NVARCHAR(200) = 'All'
	--DECLARE @FeeEarner NVARCHAR(200) ='All'



	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Department = 'All'  SET @Department = NULL
	IF @Team = 'All' SET @Team = NULL
	IF @FeeEarner = 'All' SET @FeeEarner = NULL

	DECLARE @nWeek INT = datepart(ww, getdate())
	DECLARE @nYear INT = datepart(YEAR, getdate()) 



	SELECT a.client 
	,[matter number]
	,[matter description]
	,[matter owner]
	,[team]
	,[department]
	,[Client Name]
	,[date opened]
	,[date closed]
	,[work type code]
	,[work type] 
	,[fee arrangement]
	,[referral reason] 
	,[present position] 
	,[profit costs billed]
	,[total billed]
	,[date of last bill]
	,[date of last time record]
	,[wip]
	,[unbilled disbursements]
	,[Unpaid bill balance]
	,[client balance]
	,[MI exception number]
	,RedLogic
	,WorktypeException
	,case_id
	,Leaver
	,CASE WHEN DATEDIFF(month,[date of last time record],GETDATE()) >3 AND ISNULL(wip,0)<=50 THEN 'Orange' ELSE NULL END  AS AmberLogic
	FROM dbo.ClaimsMSChecklistData a
	LEFT OUTER JOIN axxia01.dbo.cashdr
	 ON a.client=cashdr.client collate database_default
	 AND a.[matter number]=cashdr.matter collate database_default
	WHERE a.CurrentWeek=@nWeek
	AND a.CurrentYear =@nYear
	AND a.department=ISNULL(@Department,a.department)
	AND a.team=ISNULL(@Team,a.team)
	AND a.[matter owner]=ISNULL(@FeeEarner,[matter owner])






GO
