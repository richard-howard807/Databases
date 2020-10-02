SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[output_wip_issues] (@client_code CHAR(8), @matter_number CHAR(8)) 
RETURNS  VARCHAR(MAX)

AS 

BEGIN 
DECLARE @output_wip_issues varchar(MAX)	;
 
SELECT  @output_wip_issues = 
(				/*
                CASE 
                WHEN 
                stage_dim_detail_07_finance_calc_join.output_wip_issues_billed_exceeds_ff IS NULL THEN ''
                ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_billed_exceeds_ff 
                +
                ', '
                END )
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve 
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve_fee IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve_fee
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve_wip IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_defence_costs_reserve_wip 
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_final_bill_time_recorded IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_final_bill_time_recorded
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_not_changed IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_not_changed
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_possible_closure IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_possible_closure 
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_present_position IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_present_position
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_ready_closure IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_ready_closure
                +
                ', '
                END)
                + 
				*/
(CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_requires_clarification IS NULL THEN '' ELSE
stage_dim_detail_07_finance_calc_join.output_wip_issues_requires_clarification
+
', '
END)
                /*
				+
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_thirty_days IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_thirty_days
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_days IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_days
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_exceeds_ff_value IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_exceeds_ff_value
                +
                ', '
                END)
                +
                (CASE WHEN stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_exceeds_output_wip IS NULL THEN '' ELSE
                stage_dim_detail_07_finance_calc_join.output_wip_issues_wip_exceeds_output_wip
                +
                ', '
                END)
				 */
+				  
(CASE WHEN stage_dim_detail_07_finance_calc_join.output_wi_issue_ff IS NULL THEN '' ELSE
stage_dim_detail_07_finance_calc_join.output_wi_issue_ff
+
', '
END)
+ 
(CASE WHEN stage_dim_detail_05_finance_text.output_wip_percentage_complete IS NULL 
AND stage_dim_detail_05_finance_text.output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee'

THEN 'Percentage Completion Column Blank'
+
', '
ELSE ''

END)
)

FROM stage_dim_detail_07_finance_calc_join
LEFT OUTER JOIN stage_dim_detail_05_finance_text
ON dbo.stage_dim_detail_07_finance_calc_join.client_code = stage_dim_detail_05_finance_text.client_code
AND dbo.stage_dim_detail_07_finance_calc_join.matter_number = stage_dim_detail_05_finance_text.matter_number
WHERE stage_dim_detail_07_finance_calc_join.client_code = @client_code
AND stage_dim_detail_07_finance_calc_join.matter_number = @matter_number;

RETURN @output_wip_issues	 ;

END 	   ;


GO
