SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[EsureMonthlyDataBuild]

AS
BEGIN 


DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE
SET @StartDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101))
SET @EndDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),101))


DECLARE @bill_cal_month_no AS INT
DECLARE @bill_cal_year AS INT
DECLARE @bill_cal_month_name AS NVARCHAR(7)

SET @bill_cal_month_no=(SELECT DISTINCT bill_cal_month_no FROM red_dw.dbo.dim_bill_date AS ReportingPeriods
		WHERE ReportingPeriods.bill_date BETWEEN @StartDate AND @EndDate)

SET @bill_cal_year=(SELECT DISTINCT bill_cal_year FROM red_dw.dbo.dim_bill_date AS ReportingPeriods
		WHERE ReportingPeriods.bill_date BETWEEN @StartDate AND @EndDate)


SET @bill_cal_month_name=(SELECT DISTINCT bill_cal_month_name FROM red_dw.dbo.dim_bill_date AS ReportingPeriods
		WHERE ReportingPeriods.bill_date BETWEEN @StartDate AND @EndDate)

		

DELETE FROM  dbo.EnsureHistoryData
WHERE [Year Period]=YEAR(@StartDate)
AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10))

INSERT INTO dbo.EnsureHistoryData
(
    master_client_code,
    master_matter_number,
    MatterDescription,
    [Date Opened],
    [Date Closed],
    [Our Reference],
    [Claim Number],
    Insured,
    [TCD Handler],
    [Weightmans Handler],
    [Reason for Issue],
    [Litigation Avoidable],
    [Damages Claimed],
    [Damages Agreed],
    [Claimed Vs Settled],
    [Time to Settled(Days)],
    [Total Weightmans Profit Costs],
    [Total Disbursements],
    Narrative,
    NewInstruction,
    ClosedInstruction,
    ProceedingsIssued,
    [Date ProceedingsIssued],
    [Date Claim Concluded],
    [Year Period],
    Period,
    NewLitigated,
    bill_cal_month_no,
    bill_cal_year,
    bill_cal_month_name,
	[Name of Claimant],
	[Date Instructions Received],
	[Instruction Type],
	[Date Proceedings Served],
	[Present Position],
	[Date Claimants Costs Settled],
	[Claimants Costs Claimed],
	[Claimants Costs Paid],
	[Claimants Costs Savings]
)
SELECT master_client_code 
,master_matter_number
,matter_description AS MatterDescription
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,dim_client_involvement.client_reference AS [Our Reference]
,insuredclient_reference AS [Claim Number]
,insuredclient_name AS [Insured]
,clients_claims_handler_surname_forename AS [TCD Handler]
,matter_owner_full_name AS [Weightmans Handler]
,'' AS [Reason for Issue]
,was_litigation_avoidable AS [Litigation Avoidable]
,damages_reserve AS [Damages Claimed]
,damages_paid AS [Damages Agreed]
,ISNULL(damages_reserve,0) - ISNULL(damages_paid,0) AS [Claimed Vs Settled]
,DATEDIFF(DAY,date_opened_case_management,date_claim_concluded) AS [Time to Settled(Days)]
,defence_costs_billed AS [Total Weightmans Profit Costs]
,ISNULL(unpaid_disbursements,0) + ISNULL(paid_disbursements,0) AS [Total Disbursements]
,'' AS [Narrative]
,CASE WHEN date_opened_case_management BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS NewInstruction
,CASE WHEN date_claim_concluded BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS ClosedInstruction
,proceedings_issued AS [ProceedingsIssued]
,dim_detail_core_details.date_proceedings_issued AS [Date ProceedingsIssued]
,date_claim_concluded AS [Date Claim Concluded]
,YEAR(@StartDate) AS[Year Period]
,'P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) AS [Period]
,CASE WHEN dim_detail_core_details.date_proceedings_issued BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS NewLitigated
,@bill_cal_month_no AS bill_cal_month_no
,@bill_cal_year AS bill_cal_year
,@bill_cal_month_name AS bill_cal_month_name
, dim_claimant_thirdparty_involvement.claimant_name					AS [Name of Claimant]
, dim_detail_core_details.date_instructions_received				AS [Date Instructions Received]
, dim_matter_worktype.work_type_group								AS [Instruction Type]
, NULL																AS [Date Proceedings Served]
, dim_detail_core_details.present_position							AS [Present Position]
, dim_detail_outcome.date_costs_settled								AS [Date Claimants Costs Settled]
, fact_finance_summary.tp_total_costs_claimed						AS [Claimants Costs Claimed]
, fact_finance_summary.total_tp_costs_paid							AS [Claimants Costs Paid]
, ISNULL(fact_finance_summary.tp_total_costs_claimed, 0) - ISNULL(fact_finance_summary.total_tp_costs_paid, 0)		AS [Claimants Costs Savings]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
	ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
		AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
	ON dim_detail_court.client_code = dim_matter_header_current.client_code
		AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='433281'
AND date_opened_case_management>='2020-12-01'
AND dim_matter_header_current.matter_number <>'00000011'

END 


GO
