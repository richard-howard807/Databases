SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*
	Author:  Lucy Dickinson
	Date:	21/02/2019  
	NHS Resolution Dashboard Query:  Pre-Aggregation the data and then unioning the detail level
										This procedure rely's on the table [Visualisation].[dbo].[nhs_panel_averages] (which Jill Sheridan should be updating)
										and the View Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages] which gets the basic data.

	Note;  There is probably a better way of doing this but I couldn't find it, happy for anyone to with a better idea to help.


*/



CREATE PROCEDURE [dbo].[nhs_panel_comparison_figures]
AS



DECLARE @start_month DATE  

SELECT @start_month= MIN([Month]) FROM [Visualisation].[dbo].[nhs_panel_averages]
DECLARE @end_month DATE 
SELECT  @end_month = MAX ([Month]) FROM [Visualisation].[dbo].[nhs_panel_averages]


/*

	Defence Costs:  Weightmans
	
*/

SELECT nData.[Level],
		nData.[Scheme],
		nData.[Month],
		nData.[Banding],
		nData.windows_user_name,
		nData.matter_owner_name,
		nData.office,
		nData.client_code,
		nData.matter_number,

		SUM([Damages Paid]) [Damages Paid],
		SUM([Defence Costs]) [Defence Costs],
		SUM([Shelf Life]) [Shelf Life]

FROM
(
	SELECT 

		'Weightmans' [Level]
		  ,[Scheme]
		  ,defence_costs_month [Month]
		  ,banding [Banding]
		  ,NULL [Damages Paid]
		  ,AVG([defence_costs_inc_disbs]) [Defence Costs]
		  ,NULL [Shelf Life]
		  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

	FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
	WHERE defence_costs_month BETWEEN @start_month AND @end_month
	AND [defence_costs_inc_disbs] IS NOT NULL 
	GROUP BY  [Scheme],
		  defence_costs_month ,
		  banding 


UNION ALL

	SELECT 

		'Weightmans' [Level]
		  ,[Scheme]
		  ,defence_costs_month [Month]
		  ,'Overall' [Banding]
		  ,NULL [Damages Paid]
		  ,AVG([defence_costs_inc_disbs]) [Defence Costs]
		  ,NULL [Shelf Life]
		  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

	FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
	WHERE defence_costs_month BETWEEN @start_month AND @end_month
	AND [defence_costs_inc_disbs] IS NOT NULL 
	GROUP BY  [Scheme],
		  defence_costs_month 
     
	 UNION ALL

	 /* Liverpool: Defence Costs */

SELECT 

	'Liverpool' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,banding [Banding]
      ,NULL [Damages Paid]
      ,AVG([defence_costs_inc_disbs]) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND [defence_costs_inc_disbs] IS NOT NULL 
AND [Office] = 'Liverpool'
GROUP BY  [Scheme],
      defence_costs_month ,
      banding 


UNION ALL

SELECT 

	'Liverpool' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,'Overall' [Banding]
      ,NULL [Damages Paid]
      ,AVG([defence_costs_inc_disbs]) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND [defence_costs_inc_disbs] IS NOT NULL 
AND [Office] = 'Liverpool'
GROUP BY  [Scheme],
      defence_costs_month 


UNION ALL

/*
		Weightmans: Damages Paid
*/



SELECT 

	'Weightmans' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,banding [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00)[Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
GROUP BY  [Scheme],
      [damages_and_shelf_month] ,
      banding 

UNION ALL

SELECT 

	'Weightmans' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,'Overall' [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00) [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )

GROUP BY  [Scheme],
      [damages_and_shelf_month] 


/* Liverpool:  Damages Paid and Shelf Life*/

UNION ALL


SELECT 

	'Liverpool' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,banding [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00)[Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'Liverpool'
GROUP BY  [Scheme],
      [damages_and_shelf_month] ,
      banding 

UNION ALL

SELECT 

	'Liverpool' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,'Overall' [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00) [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'Liverpool'
GROUP BY  [Scheme],
      [damages_and_shelf_month] 

/*
		Birmingham Defence Costs
*/

 UNION ALL

SELECT 

	'Birmingham' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,banding [Banding]
      ,NULL [Damages Paid]
      ,AVG([defence_costs_inc_disbs]) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
	  ,'' matter_owner_name
	  ,'' office
	  ,'' client_code
	  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND [defence_costs_inc_disbs] IS NOT NULL 
AND [Office] = 'Birmingham'
GROUP BY  [Scheme],
      defence_costs_month ,
      banding 


UNION ALL

SELECT 

	'Birmingham' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,'Overall' [Banding]
      ,NULL [Damages Paid]
      ,AVG(defence_costs_inc_disbs) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND defence_costs_inc_disbs IS NOT NULL 
AND [Office] = 'Birmingham'
GROUP BY  [Scheme],
      defence_costs_month 


UNION ALL


SELECT 

	'Birmingham' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,banding [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00)[Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'Birmingham'
GROUP BY  [Scheme],
      [damages_and_shelf_month] ,
      banding 

UNION ALL

SELECT 

	'Birmingham' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,'Overall' [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00) [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'Birmingham'
GROUP BY  [Scheme],
      [damages_and_shelf_month] 




/*
		London Defence Costs
*/

 UNION ALL

SELECT 

	'London' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,banding [Banding]
      ,NULL [Damages Paid]
      ,AVG(defence_costs_inc_disbs) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
	 ,'' matter_owner_name
	 ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND defence_costs_inc_disbs IS NOT NULL 
AND [Office] = 'London'
GROUP BY  [Scheme],
      defence_costs_month ,
      banding 


UNION ALL

SELECT 

	'London' [Level]
      ,[Scheme]
      ,defence_costs_month [Month]
      ,'Overall' [Banding]
      ,NULL [Damages Paid]
      ,AVG(defence_costs_inc_disbs) [Defence Costs]
      ,NULL [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE defence_costs_month BETWEEN @start_month AND @end_month
AND defence_costs_inc_disbs IS NOT NULL 
AND [Office] = 'London'
GROUP BY  [Scheme],
      defence_costs_month 


UNION ALL


SELECT 

	'London' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,banding [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00)[Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'London'
GROUP BY  [Scheme],
      [damages_and_shelf_month] ,
      banding 

UNION ALL

SELECT 

	'London' [Level]
      ,[Scheme]
      ,[damages_and_shelf_month] [Month]
      ,'Overall' [Banding]
      ,AVG(damages_paid)  [Damages Paid]
      ,NULL [Defence Costs]
      ,AVG(shelf_life/365.00) [Shelf Life]
	  ,'' windows_user_name
		  ,'' matter_owner_name
		  ,'' office
		  ,'' client_code
		  ,'' matter_number

FROM Visualisation.[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [damages_and_shelf_month] BETWEEN @start_month AND @end_month
AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )
AND [Office] = 'London'
GROUP BY  [Scheme],
      [damages_and_shelf_month] 


UNION ALL

	SELECT 

	'Weightmans Matter Level' [Level]
	  ,[Scheme]
      ,[defence_costs_month] [Month]
	  ,[banding] [Banding]
	  ,NULL [Damages Paid]
      ,[defence_costs_inc_disbs] [Defence Costs]
      ,NULL [Shelf Life] 
     -- ,[damages_and_shelf_month]
      --,[shelf_life]
	  ,[windowsusername] windows_user_name
	  ,[matter_owner_full_name] matter_owner_name
	  ,[Office] [office]
	  ,[master_client_code] [client_code]
      ,[master_matter_number] [matter_number]

FROM [Visualisation].[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE [defence_costs_month] BETWEEN @start_month AND @end_month
AND defence_costs_inc_disbs IS NOT NULL
 



UNION ALL

	SELECT 

	'Weightmans Matter Level' [Level]
	  ,[Scheme]
      ,[damages_and_shelf_month] [Month]
	  ,[banding] [Banding]
	  ,damages_paid [Damages Paid]
      ,NULL [Defence Costs]
      ,shelf_life [Shelf Life] 
     -- ,[damages_and_shelf_month]
      --,[shelf_life]
	  ,[windowsusername] windows_user_name
	  ,[matter_owner_full_name] matter_owner_name
	  ,[Office] [office]
	  ,[master_client_code] [client_code]
      ,[master_matter_number] [matter_number]

FROM [Visualisation].[dbo].[nhs_weightmans_clinical_and_risk_averages]
WHERE  [damages_and_shelf_month] BETWEEN @start_month AND @end_month
 AND NOT ([damages_paid] IS NULL AND shelf_life IS NULL )




) nData

WHERE NOT ([nData].[Defence Costs] = 0 AND [nData].[Damages Paid] IS NULL AND nData.[Shelf Life] IS NULL)

GROUP BY nData.[Level],
		nData.[Scheme],
		nData.[Month],
		nData.[Banding],
		nData.windows_user_name,
		nData.matter_owner_name,
		nData.office,
		nData.client_code,
		nData.matter_number


UNION ALL

SELECT CASE WHEN [Level] = 'Panel Total' THEN 'Panel' ELSE [Level] END [Level]
		, [Scheme]
		,CAST([Month] AS DATE) [Month]
		,[Banding]
		,''
		,CASE WHEN [Level] = 'Panel Total' THEN 'Target' ELSE '' END
		,''
		,''
		,''
		, [Damages Paid],[Defence Costs],[Shelf Life]


FROM [Visualisation].[dbo].[nhs_panel_averages]
			

	  
GO
