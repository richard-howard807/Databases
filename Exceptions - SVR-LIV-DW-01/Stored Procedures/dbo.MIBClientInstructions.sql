SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MIBClientInstructions] 
-- EXEC [dbo].[MIBClientInstructions] '2017-01-01','2018-11-08','Exclusive Corporate|Missing','Commercial National'
(
@StartDate AS DATE
,@EndDate AS DATE
,@ServiceCategory AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)

)
AS
BEGIN
IF OBJECT_ID('tempdb..#ServiceCategory') IS NOT NULL DROP TABLE #ServiceCategory
IF OBJECT_ID('tempdb..#Team') IS NOT NULL DROP TABLE #Team

SELECT ListValue  INTO #ServiceCategory FROM Reporting.dbo.udt_TallySplit(',', @ServiceCategory)
SELECT ListValue  INTO #Team FROM Reporting.dbo.udt_TallySplit(',', @Team)

SELECT [Reference]
,[Fee earner]
,[matter description]
,[Service Category]--  - if a VF matter say "Recoveries"
,[team]
,[date opened]
,[present position]
,[date claim concluded]
,[Profit costs billed]
,[Date closed]
,[SourceSystem]
,NumberMatters
,MonthPeriod
,MonthNumber
,YearNumber
FROM
(
SELECT dim_matter_header_current.client_code  + ' ' + dim_matter_header_current.matter_number collate database_default AS [Reference]
,name collate database_default AS [Fee earner]
,matter_description collate database_default AS [matter description]
,CASE WHEN dim_detail_client.[service_category] IS NULL THEN 'Missing' ELSE dim_detail_client.[service_category] END  collate database_default AS [Service Category]--  - if a VF matter say "Recoveries"

,hierarchylevel4hist collate database_default AS [team]
,date_opened_case_management AS [date opened]
,dim_detail_core_details.[present_position] collate database_default AS [present position]
,dim_detail_outcome.[date_claim_concluded] AS [date claim concluded]
,defence_costs_billed AS [Profit costs billed]
,date_closed_practice_management AS [Date closed]
,'FED/MS' collate database_default AS [SourceSystem]
,1 AS NumberMatters
,DATENAME(Month,date_opened_case_management) AS MonthPeriod
,MONTH(date_opened_case_management) AS MonthNumber
,Year(date_opened_case_management) AS YearNumber
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code collate database_default AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_detail_client.client_code 
 AND dim_matter_header_current.matter_number=dim_detail_client.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_detail_outcome.client_code 
 AND dim_matter_header_current.matter_number=dim_detail_outcome.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_detail_core_details.client_code 
 AND dim_matter_header_current.matter_number=dim_detail_core_details.matter_number   
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code 
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number    
WHERE client_group_name='MIB'
AND date_opened_case_management>='2017-01-01'
AND dim_matter_header_current.client_code NOT IN('00030645')
AND reporting_exclusions=0
AND date_opened_case_management BETWEEN @StartDate AND @EndDate
UNION
SELECT MIB_ClaimNumber AS [Reference]
,Name AS [Fee earner]
,AccountDescription AS [matter description]
,'Recoveries' AS [Service Category]--  - if a VF matter say ""
,'Commercial Recoveries' AS [team]
,DateOpened AS [date opened]
,MilestoneDescription AS [present position]
,NULL AS [date claim concluded]
,NULL AS [Profit costs billed]
,CLO_ClosedDate AS [Date closed]
,'VisualFiles' AS [SourceSystem]
,1 AS NumberMatters
,DATENAME(Month,DateOpened) AS MonthPeriod
,MONTH(DateOpened) AS MonthNumber
,Year(DateOpened) AS YearNumber
FROM [SQL2008SVr].VFile_Streamlined.dbo.AccountInformation  WITH(NOLOCK)
LEFT OUTER JOIN [SQL2008SVr].VFile_Streamlined.dbo.ClientScreens WITH(NOLOCK) 
 ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN [SQL2008SVr].VFile_Streamlined.dbo.fee ON 
			RIGHT(level_fee_earner,3)=fee_earner
WHERE ClientName='MIB'
AND DateOpened >='2017-01-01'
AND ISNULL(MIB_ClaimNumber, '')<> ''
AND MatterCode NOT IN(259476,260037,260044,260061,260070,260074,264985)
AND DateOpened BETWEEN @StartDate AND @EndDate
) AS AllData

INNER JOIN #ServiceCategory AS ServiceCategory ON ServiceCategory.ListValue COLLATE database_default = [Service Category] COLLATE database_default
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = [Team] COLLATE database_default
END
GO
