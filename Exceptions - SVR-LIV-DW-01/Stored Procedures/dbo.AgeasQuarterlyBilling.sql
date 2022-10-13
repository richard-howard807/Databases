SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


------------------------------------------------------------
-- ES 20191128  40434 Removed Lisa Cain 2090 from lead matter exclusion
------------------------------------------------------------

CREATE PROCEDURE [dbo].[AgeasQuarterlyBilling] --EXEC dbo.AgeasQuarterlyBilling '2018-01-01','2018-12-31'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2018-01-01'
--SET @EndDate='2018-12-31'


BEGIN
SELECT COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference) AS [Ageas reference]
,dim_client_involvement.insuredclient_name AS [Ageas policyholder]
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,total_damages_and_tp_costs_reserve AS [Current Reserve]
,MatterOwner.[name] AS [Lead Fee Earner Name]
,dim_bill.bill_number
,dim_bill_date.bill_date
,SUM(fact_all_time_activity.time_charge_value) AS Total
,SUM(wiphrs) AS HrsBilled

,SUM(CASE WHEN RTRIM(TimeFE.fed_code)=RTRIM(MatterOwner.fed_code) AND TimeFE.fed_code NOT  IN 
('5547','3216','3691','1924','4493','4560','4348','4815','1713','4234','3113','5113','5386','5644','3094','4878','4105','3662'
,'4410','2033','5607','4204','4846','4387','5009','5427','4941','5569','4660','4828','4874','4456') 
THEN fact_all_time_activity.time_charge_value ELSE 0 END)  AS [Lead Billed]

,SUM(CASE WHEN RTRIM(TimeFE.fed_code)=RTRIM(MatterOwner.fed_code) AND TimeFE.fed_code NOT  IN 
('5547','3216','3691','1924','4493','4560','4348','4815','1713','4234','3113','5113','5386','5644','3094','4878','4105','3662'
,'4410','2033','5607','4204','4846','4387','5009','5427','4941','5569','4660','4828','4874','4456') THEN wiphrs ELSE 0 END)  AS [Lead Billed Hrs]

,SUM(CASE WHEN TimeFE.fed_code IN 
('5547','3216','3691','1924','4493','4560','4348','4815','1713','4234','3113','5113','5386','5644','3094','4878','4105','3662'
,'4410','2033','5607','4204','4846','4387','5009','5427','4941','5569','4660','4828','4874','4456') THEN  fact_all_time_activity.time_charge_value ELSE 0 END)  AS [Cost Team Billed]

,SUM(CASE WHEN TimeFE.fed_code IN 
('5547','3216','3691','1924','4493','4560','4348','4815','1713','4234','3113','5113','5386','5644','3094','4878','4105','3662'
,'4410','2033','5607','4204','4846','4387','5009','5427','4941','5569','4660','4828','4874','4456') THEN wiphrs  ELSE 0 END)  AS [Cost Team Billed Hrs]
,tier_1_3_case
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fact_all_time_activity.dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill
 ON fact_all_time_activity.dim_bill_key=dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeFE
 ON  fact_all_time_activity.dim_fed_hierarchy_history_key=TimeFE.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS MatterOwner
 ON  dim_matter_header_current.fee_earner_code=MatterOwner.fed_code collate database_default AND MatterOwner.dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_all_time_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
INNER JOIN red_dw.dbo.fact_dimension_main ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON fact_dimension_main.dim_detail_client_key=dim_detail_client.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON fact_dimension_main.dim_detail_claim_key=dim_detail_claim.dim_detail_claim_key

LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON fact_dimension_main.dim_client_involvement_key=dim_client_involvement.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary 
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code AND 
 dim_matter_header_current.matter_number=fact_finance_summary.matter_number
WHERE dim_matter_header_current.client_group_name='Ageas'
AND dim_bill_date.bill_date BETWEEN @StartDate AND @EndDate
AND dim_bill.bill_number <>'PURGE'
GROUP BY COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference) 
,dim_client_involvement.insuredclient_name
,MatterOwner.[name] 
,dim_bill.bill_number
,dim_bill_date.bill_date
,dim_matter_header_current.client_code 
,dim_matter_header_current.matter_number 
,total_damages_and_tp_costs_reserve
,tier_1_3_case

ORDER BY dim_bill_date.bill_date
END
GO
