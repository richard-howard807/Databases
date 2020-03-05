SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NewMattersAfter3Years] --EXEC [dbo].[NewMattersAfter3Years] '2017-08-23','2017-08-23'
(	@StartDate	date
,	@EndDate	date
)


As
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SELECT * FROM 
(
Select	MostRecent.mg_client	AS Client
	,	caclient.cl_clname		AS ClientName
	,	MostRecent.mg_matter	AS Matter
	,	MostRecent.mg_feearn	AS FeeEarner
	,	MostRecent.mg_datopn	AS DateMatterOpened
	,	Previous.mg_feearn		AS	PreviousFeeEarner
	,	Previous.mg_datopn		AS	PreviousDateMatterOpened
	,	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) AS NoYears
from
	(
	SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	MostRecent

inner join 
	(
			SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	Previous
	
	ON	MostRecent.mg_client = Previous.mg_client
inner join	axxia01.dbo.caclient
	ON	MostRecent.mg_client = caclient.cl_accode

WHERE	MostRecent.OrderID = 1
	AND Previous.OrderID = 2
	AND	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) >= 3
	AND	MostRecent.mg_datopn BETWEEN @StartDate AND @EndDate
	

) AS AllData
WHERE DATEDIFF(month,PreviousDateMatterOpened,DateMatterOpened)/12>=3
GO
