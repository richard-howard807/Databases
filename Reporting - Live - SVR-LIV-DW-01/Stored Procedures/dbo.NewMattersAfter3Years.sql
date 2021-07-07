SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[NewMattersAfter3Years] --EXEC [dbo].[NewMattersAfter3Years] '2017-08-23','2017-08-23'
(	@StartDate	DATE
,	@EndDate	DATE
)


AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SELECT AllData.Client,
       AllData.ClientName,
       AllData.Matter,
       AllData.FeeEarner,
       AllData.DateMatterOpened,
       AllData.PreviousFeeEarner,
       AllData.PreviousDateMatterOpened,
       AllData.NoYears
  
	---------- Extra Data Request 105668

,dim_client.[branch]
,dim_client.[client_type]
,dim_client.[client_group_name]
,dim_client.[client_partner_name]
,dim_client.[open_date]
,dim_client.[email]
,dim_client.[sector]
,dim_client.[segment]
,dim_client.[sub_sector]
,dim_client.[created_by]
,dim_client.[business_source_name]
,dim_client.[postcode]
,dim_client.[referrer_type]
,dim_client.[business_source]
FROM 
(
SELECT	MostRecent.mg_client	AS Client
	,	caclient.cl_clname		AS ClientName
	,	MostRecent.mg_matter	AS Matter
	,	MostRecent.mg_feearn	AS FeeEarner
	,	MostRecent.mg_datopn	AS DateMatterOpened
	,	Previous.mg_feearn		AS	PreviousFeeEarner
	,	Previous.mg_datopn		AS	PreviousDateMatterOpened
	,	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) AS NoYears
FROM
	(
	SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	MostRecent

INNER JOIN 
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
INNER JOIN	axxia01.dbo.caclient
	ON	MostRecent.mg_client = caclient.cl_accode

WHERE	MostRecent.OrderID = 1
	AND Previous.OrderID = 2
	AND	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) >= 3
	AND	MostRecent.mg_datopn BETWEEN @StartDate AND @EndDate
	

) AS AllData
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON AllData.Client=client_code
WHERE DATEDIFF(MONTH,PreviousDateMatterOpened,DateMatterOpened)/12>=3
GO
