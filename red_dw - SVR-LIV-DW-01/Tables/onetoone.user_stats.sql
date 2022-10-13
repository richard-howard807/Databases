CREATE TABLE [onetoone].[user_stats]
(
[snapshot_date] [date] NULL,
[fin_year] [int] NULL,
[data_for_month] [int] NULL,
[fed_code] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[month_or_ytd] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[Billable_target] [numeric] (38, 2) NULL,
[Actual_Billed] [numeric] (38, 2) NULL,
[Diff_billed] [numeric] (38, 2) NULL,
[Diff_billed_percent] [numeric] (38, 6) NULL,
[chargable_hours_target] [numeric] (38, 2) NULL,
[Actaul_chargable_hours] [numeric] (38, 6) NULL,
[Diff_hours] [numeric] (38, 2) NULL,
[Diff_hours_percent] [numeric] (38, 6) NULL,
[totalentitlementdays] [numeric] (25, 2) NULL,
[remaining] [numeric] (38, 2) NULL,
[remaining_fte_working_days] [int] NULL,
[Working_days_left] [numeric] (38, 2) NULL,
[AVG_Hrs_To_Hit_Target_Year] [numeric] (38, 6) NULL,
[yearly_working_days] [int] NULL,
[AVG_Hrs_To_Hit_Target_Month_End] [numeric] (38, 6) NULL,
[Target_Recovery_Rate] [numeric] (38, 6) NULL,
[Actual_Recovery_Rate] [numeric] (38, 6) NULL,
[Recovery_rate_diff] [numeric] (38, 6) NULL,
[Recovery_rate_diff_percent] [numeric] (38, 6) NULL,
[write_off_amt_hourly] [numeric] (38, 2) NULL,
[write_off_amt_fixed] [numeric] (38, 2) NULL,
[wip_value] [numeric] (38, 2) NULL,
[Claim_concluded_but_costs_outstanding] [int] NULL,
[Claim_and_costs_concluded_but_recovery_outstanding] [int] NULL,
[Claim_and_costs_outstanding] [int] NULL,
[Final_bill_sent_unpaid] [int] NULL,
[Present_Position_Blank] [int] NULL,
[Final_bill_due_claim_and_costs_concluded] [int] NULL,
[To_be_closed_minor_balances_to_be_clear] [int] NULL,
[Client_balance] [numeric] (38, 2) NULL,
[Total_Budget_Year] [numeric] (38, 2) NULL,
[AVG_Elapsed_Days_Closed_Cases] [int] NULL,
[Repudiation_Rate_Percent] [float] NULL,
[bill_balance] [int] NULL,
[client_and_bill_balance] [int] NULL,
[client_balance] [int] NULL,
[to_be_closed] [int] NULL,
[Fixed_fee_matters] [int] NULL,
[Hourly_fee_matters] [int] NULL,
[TotalMatters] [int] NULL,
[Percent_fixed_fee_matters] [float] NULL,
[Percent_hourly_fee_matters] [float] NULL,
[no_of_fixed_fee_matters_to_hit_target] [int] NOT NULL,
[Disb_0_30_Days] [float] NULL,
[Disb_31_90_Days] [float] NULL,
[Disb_90_Days] [float] NULL,
[Debt_0_30_Days] [float] NULL,
[Debt_31_180_Days] [float] NULL,
[Debt_180_Days] [float] NULL,
[Repudiation_Rate_Percent_PY] [float] NULL,
[Total_Exceptions] [int] NULL,
[AVG_Exceptions] [float] NULL,
[AVG_Elapsed_Days_Closed_Cases_PY] [int] NULL,
[debt_target_ytd] [numeric] (13, 2) NULL,
[Actual_Recovery_Rate_PY] [numeric] (38, 6) NULL,
[wip_value_py] [numeric] (38, 2) NULL,
[Fee_Arrangment_Exception_Count] [int] NULL,
[Revenue_Est_Exception_Count] [int] NULL,
[Disb_Est_Exception_Count] [int] NULL,
[bill_balance_lta] [int] NULL,
[client_and_bill_balance_lta] [int] NULL,
[client_balance_lta] [int] NULL,
[to_be_closed_lta] [int] NULL,
[Utilisatino_Percent] [float] NULL,
[Debt_31_90_Days] [numeric] (13, 2) NULL,
[Debt_90_Days] [numeric] (13, 2) NULL,
[Utilisation_Percent] [float] NULL,
[Actual_chargable_hours] [numeric] (38, 6) NULL,
[Days_in_the_office] [int] NULL
) ON [WRK_TAB]
GO
GRANT SELECT ON  [onetoone].[user_stats] TO [SBC\SQL - DataReader access to DW-01 For Software Tester]
GO
GRANT SELECT ON  [onetoone].[user_stats] TO [SBC\SQL ROLE - DS_MI_ANALYST]
GO
