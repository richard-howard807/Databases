SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 09/11/2022
-- Description: #177430 HR Rely BOA Report - to replace Finance Systems report on SVR-LIV-3ESQ-01 
-- =============================================

CREATE PROCEDURE [dbo].[hr_rely_boa]	--EXEC Reporting.dbo.hr_rely_boa

AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #hr_rely_matters
DROP TABLE IF EXISTS #original_fee
DROP TABLE IF EXISTS #allocations
DROP TABLE IF EXISTS #wip

SELECT 
	Matter.Number
	, Matter.DisplayName
	, Client.DisplayName		AS client_name
	, Matter.MattIndex
INTO #hr_rely_matters
FROM TE_3E_Prod.dbo.Matter
	INNER JOIN TE_3E_Prod.dbo.Client
		ON Client.ClientIndex = Matter.Client
WHERE
	Matter.MattStatus = 'OP'
	AND (LOWER(Matter.DisplayName) LIKE '%hr%rely%'
		OR LOWER(Matter.DisplayName) LIKE '%hrr%'
		OR Matter.Number IN ('HRR00076-5','HRR00080-29','HRR00083-12','HRR00088-15','HRR00088-17','HRR00093-4','HRR00123-10','HRR00123-6','HRR00133-13','HRR00136-11','HRR00151-5','834944-3','216775-12'))
	AND Client.Number <> '30645'
	--AND Matter.Number = '173588-30'


SELECT * 
INTO #original_fee
FROM (
	SELECT
		#hr_rely_matters.Number
		, #hr_rely_matters.client_name
		, InvMaster.OrgBOA
		, ROUND(InvMaster.OrgBOA/12, 2)	AS  monthly_figure
		, InvMaster.InvDate			AS boa_start_date 
		, DATEDIFF(MONTH, InvMaster.InvDate, GETDATE()) +1		AS age_in_months
		, ROW_NUMBER() OVER(PARTITION BY #hr_rely_matters.Number ORDER BY InvMaster.InvDate) AS row_num
	FROM #hr_rely_matters
		INNER JOIN TE_3E_Prod.dbo.InvMaster
			ON #hr_rely_matters.MattIndex = InvMaster.LeadMatter
	WHERE
		InvMaster.InvDate >= '20170401'
	) AS boa
WHERE
	boa.row_num = 1



SELECT
	boa.Number
	, boa.client_name
	, ABS(SUM(boa.OrgBOA))		AS allocated_to_date
	, MAX(boa.InvDate)		AS last_bill_date
	, MIN(boa.age)		AS months_since_last_allocation
INTO #allocations
FROM (
	SELECT
		#hr_rely_matters.Number
		, #hr_rely_matters.client_name
		, InvMaster.OrgBOA
		, InvMaster.InvDate
		, DATEDIFF(MONTH, InvMaster.InvDate, GETDATE()) 		AS age
		, ROW_NUMBER() OVER(PARTITION BY #hr_rely_matters.Number ORDER BY InvMaster.InvDate) AS row_num
	
	FROM #hr_rely_matters
		INNER JOIN TE_3E_Prod.dbo.InvMaster
			ON #hr_rely_matters.MattIndex = InvMaster.LeadMatter
	WHERE
		InvMaster.InvDate >= '20170401'
	) AS boa
WHERE
	boa.row_num > 1 
GROUP BY
	boa.Number
	, boa.client_name



SELECT 
	#hr_rely_matters.Number
	, #hr_rely_matters.client_name
	, SUM(Timecard.WIPHrs)		as wip
INTO #wip
FROM #hr_rely_matters
	INNER JOIN TE_3E_Prod.dbo.Timecard
		ON #hr_rely_matters.MattIndex = Timecard.Matter
WHERE
	Timecard.ProfMaster IS NULL
and Timecard.IsActive = 1
AND Timecard.WorkHrs <> 0
AND Timecard.IsNB = 0
AND Timecard.IsNoCharge = 0
AND ISNULL(Timecard.Disposition,'') NOT IN ('PURGE')
GROUP BY
	#hr_rely_matters.Number
	, #hr_rely_matters.client_name



SELECT 
	#hr_rely_matters.Number
	, #hr_rely_matters.client_name
	, wip	
	, #original_fee.OrgBOA
	, #original_fee.monthly_figure
	, #allocations.allocated_to_date
	, #original_fee.age_in_months
	, #allocations.last_bill_date
	, #allocations.months_since_last_allocation
	, CASE
		WHEN #original_fee.age_in_months = 12 THEN
			#original_fee.OrgBOA - #allocations.allocated_to_date
		WHEN (#original_fee.OrgBOA - #allocations.allocated_to_date) < #original_fee.monthly_figure THEN
			#original_fee.OrgBOA - #allocations.allocated_to_date
		ELSE
			#original_fee.monthly_figure * #allocations.months_since_last_allocation
	  END										AS amount_to_be_allocated
FROM #hr_rely_matters
	INNER JOIN #wip
		ON #wip.Number = #hr_rely_matters.Number 
			AND #wip.wip > 0
	INNER JOIN #original_fee
		ON #original_fee.Number = #hr_rely_matters.Number
	INNER JOIN #allocations
		ON #allocations.Number = #hr_rely_matters.Number
WHERE
	#original_fee.OrgBOA - #allocations.allocated_to_date > 0

END
GO
