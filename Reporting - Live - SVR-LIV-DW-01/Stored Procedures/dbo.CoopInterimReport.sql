SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CoopInterimReport]
----(
----@StartDate DATETIME --= '2016-01-01',
----,@EndtDate DATETIME --= '2017-01-01'
----)

(
@ClosedDate datetime 
)
AS

SET NOCOUNT ON;


--DECLARE @ClosedDate datetime 
--SET @ClosedDate='2018-12-17'

SELECT 
dim_matter_header_current.client_code AS [client]
,dim_matter_header_current.matter_number AS [matter]
,name AS [Name]
,hierarchylevel4hist AS [team]
,work_type_name AS [ds_descrn]
,work_type_code AS [mg_wrktyp]
,date_opened_case_management AS [date_opened]
,date_closed_case_management AS [date_closed]
,date_costs_settled AS [FTR087]
,outcome_of_case AS [outcome]
,date_claim_concluded AS [Date damages settled]   
,fact_finance_summary.[damages_interims] AS [A) Interim damages payments (post instruction)]               
,CASE WHEN ms_only=1 THEN  dteIntDamsPay2 ELSE NMI353.case_date END   [Date of second interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDamsPay1 ELSE NMI360.case_Value END [Amount of first interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDamsPay1 ELSE NMI361.case_date END [Date of first interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDamsPay2 ELSE NMI362.case_Value END [Amount of second interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDamsPay3 ELSE NMI364.case_Value END [Amount of third interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDamsPay3 ELSE NMI365.case_date END [Date of third interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDamsPay4 ELSE NMI366.case_Value END [Amount of fourth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDamsPay4 ELSE NMI367.case_date END [Date of fourth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDamsPay5 ELSE NMI368.case_Value END [Amount of fifth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDamsPay5 ELSE NMI369.case_date END [Date of fifth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReIntDamPay1 ELSE NMI406.case_text END COLLATE DATABASE_DEFAULT  [Reason for first interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReIntDamPay2 ELSE NMI407.case_text END COLLATE DATABASE_DEFAULT [Reason for second interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReIntDamPay3 ELSE NMI408.case_text END COLLATE DATABASE_DEFAULT [Reason for third interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReIntDamPay4 ELSE NMI409.case_text END COLLATE DATABASE_DEFAULT [Reason for fourth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReIntDamPay5 ELSE NMI410.case_text END COLLATE DATABASE_DEFAULT [Reason for fifth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPay6th ELSE NMI636.case_date END [Date of sixth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntDa6th ELSE NMI637.case_text END COLLATE DATABASE_DEFAULT [Reason for sixth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPay7th ELSE NMI638.case_Value END [Amount of seventh interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPay7th ELSE NMI639.case_date END [Date of seventh interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntDa7th ELSE NMI640.case_text END COLLATE DATABASE_DEFAULT [Reason for seventh interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPay8th ELSE NMI641.case_Value END [Amount of eighth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPay8th ELSE NMI642.case_date END [Date of eighth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntDa8th ELSE NMI643.case_text END COLLATE DATABASE_DEFAULT [Reason for eighth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPay9th ELSE NMI644.case_Value END [Amount of ninth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPay9th ELSE NMI645.case_date END [Date of ninth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntDa9th ELSE NMI646.case_text END COLLATE DATABASE_DEFAULT [Reason for ninth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa10th ELSE NMI647.case_Value END [Amount of tenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa10th ELSE NMI648.case_date END [Date of tenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD10th ELSE NMI649.case_text END COLLATE DATABASE_DEFAULT [Reason for tenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPay6th ELSE NMI650.case_Value END [Amount of sixth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa11th ELSE NMI651.case_Value END [Amount of eleventh interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa11th ELSE NMI652.case_date END [Date of eleventh interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD11th ELSE NMI653.case_text END COLLATE DATABASE_DEFAULT [Reason for eleventh interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa12th ELSE NMI654.case_Value END [Amount of twelfth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa12th ELSE NMI655.case_date END [Date of twelfth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD12th ELSE NMI656.case_text END COLLATE DATABASE_DEFAULT [Reason for twelfth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa13th ELSE NMI657.case_Value END [Amount of thirteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa13th ELSE NMI658.case_date END [Date of thirteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD13th ELSE NMI659.case_text END COLLATE DATABASE_DEFAULT [Reason for thirteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa14th ELSE NMI660.case_Value END [Amount of fourteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa14th ELSE NMI661.case_date END [Date of fourteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD14th ELSE NMI662.case_text END COLLATE DATABASE_DEFAULT [Reason for fourteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa15th ELSE NMI663.case_Value END [Amount of fifteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa15th ELSE NMI664.case_date END [Date of fifteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD15th ELSE NMI665.case_text END COLLATE DATABASE_DEFAULT [Reason for fifteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa16th ELSE NMI892.case_Value END [Amount of sixteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa16th ELSE NMI893.case_date END [Date of sixteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD16th ELSE NMI894.case_text END COLLATE DATABASE_DEFAULT [Reason for sixteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa17th ELSE NMI895.case_Value END [Amount of seventeenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa17th ELSE NMI896.case_date END [Date of seventeenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD17th ELSE NMI897.case_text END COLLATE DATABASE_DEFAULT [Reason for seventeenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa18th ELSE NMI898.case_Value END [Amount of eighteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa18th ELSE NMI899.case_date END [Date of eighteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD18th ELSE NMI900.case_text END COLLATE DATABASE_DEFAULT [Reason for eighteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa19th ELSE NMI901.case_Value END [Amount of nineteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa19th ELSE NMI902.case_date END [Date of nineteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD19th ELSE NMI903.case_text END COLLATE DATABASE_DEFAULT [Reason for nineteenth interim damages payment]
,CASE WHEN ms_only=1 THEN  curIntDaPa20th ELSE NMI904.case_Value END [Amount of twentieth interim damages payment]
,CASE WHEN ms_only=1 THEN  dteIntDaPa20th ELSE NMI905.case_date END [Date of twentieth interim damages payment]
,CASE WHEN ms_only=1 THEN  txtReasIntD20th ELSE NMI906.case_text END COLLATE DATABASE_DEFAULT [Reason for twentieth interim damages payment]

,CASE WHEN ms_only=1 THEN  curIntCoPayPost ELSE NMI066.case_value END [A) Interim costs payments (post instruction)] 
,CASE WHEN ms_only=1 THEN  curIntCostPay5 ELSE NMI358.case_value END [Amount of fifth interim costs payment]
,CASE WHEN ms_only=1 THEN  curIntCostPay1 ELSE NMI350.case_value END [Amount of first interim costs payment]
,CASE WHEN ms_only=1 THEN  curIntCostPay4 ELSE NMI356.case_value END [Amount of fourth interim costs payment]
,CASE WHEN ms_only=1 THEN  curIntCostPay2 ELSE NMI352.case_value END [Amount of second interim costs payment]
,CASE WHEN ms_only=1 THEN  curIntCostPay3 ELSE NMI354.case_value END [Amount of third interim costs payment]
,CASE WHEN ms_only=1 THEN  dteIntCostPay5 ELSE NMI359.case_date END [Date of fifth interim costs payment]
,CASE WHEN ms_only=1 THEN  dteIntCostPay1 ELSE NMI351.case_date END [Date of first interim costs payment]
,CASE WHEN ms_only=1 THEN  dteIntCostPay4 ELSE NMI357.case_date END [Date of fourth interim costs payment]
,CASE WHEN ms_only=1 THEN  dteIntCostPay2 ELSE NMI363.case_date END [Date of second interim costs payment]
,CASE WHEN ms_only=1 THEN  dteIntCostPay3 ELSE NMI370.case_date END [Date of third interim costs payment]

FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_matter_header_current.fee_earner_code=fed_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=dim_detail_outcome.client_code
 AND dim_matter_header_current.matter_number=dim_detail_outcome.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number 
LEFT OUTER JOIN MS_Prod.dbo.udMIOutcomeDamages WITH(NOLOCK)
 ON dim_matter_header_current.ms_fileid= udMIOutcomeDamages.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMIOutcomeCosts WITH(NOLOCK)
 ON dim_matter_header_current.ms_fileid= udMIOutcomeCosts.fileID 
 
 
left join axxia01.dbo.casdet NMI066 WITH(NOLOCK) on NMI066.case_id = dim_matter_header_current.case_id and NMI066.case_detail_code = 'NMI066'
left join axxia01.dbo.casdet NMI065 WITH(NOLOCK) on NMI065.case_id = dim_matter_header_current.case_id and NMI065.case_detail_code = 'NMI065'

left join axxia01.dbo.casdet NMI353 WITH(NOLOCK) on NMI353.case_id = dim_matter_header_current.case_id and NMI353.case_detail_code = 'NMI353'
left join axxia01.dbo.casdet NMI360 WITH(NOLOCK) on NMI360.case_id = dim_matter_header_current.case_id and NMI360.case_detail_code = 'NMI360'    
left join axxia01.dbo.casdet NMI361 WITH(NOLOCK) on NMI361.case_id = dim_matter_header_current.case_id and NMI361.case_detail_code = 'NMI361'
left join axxia01.dbo.casdet NMI362 WITH(NOLOCK) on NMI362.case_id = dim_matter_header_current.case_id and NMI362.case_detail_code = 'NMI362'
left join axxia01.dbo.casdet NMI364 WITH(NOLOCK) on NMI364.case_id = dim_matter_header_current.case_id and NMI364.case_detail_code = 'NMI364'
left join axxia01.dbo.casdet NMI365 WITH(NOLOCK) on NMI365.case_id = dim_matter_header_current.case_id and NMI365.case_detail_code = 'NMI365'
left join axxia01.dbo.casdet NMI366 WITH(NOLOCK) on NMI366.case_id = dim_matter_header_current.case_id and NMI366.case_detail_code = 'NMI366'
left join axxia01.dbo.casdet NMI367 WITH(NOLOCK) on NMI367.case_id = dim_matter_header_current.case_id and NMI367.case_detail_code = 'NMI367'
left join axxia01.dbo.casdet NMI368 WITH(NOLOCK) on NMI368.case_id = dim_matter_header_current.case_id and NMI368.case_detail_code = 'NMI368'
left join axxia01.dbo.casdet NMI369 WITH(NOLOCK) on NMI369.case_id = dim_matter_header_current.case_id and NMI369.case_detail_code = 'NMI369'


left join axxia01.dbo.casdet NMI406 WITH(NOLOCK) on NMI406.case_id = dim_matter_header_current.case_id and NMI406.case_detail_code = 'NMI406'
left join axxia01.dbo.casdet NMI407 WITH(NOLOCK) on NMI407.case_id = dim_matter_header_current.case_id and NMI407.case_detail_code = 'NMI407'
left join axxia01.dbo.casdet NMI408 WITH(NOLOCK) on NMI408.case_id = dim_matter_header_current.case_id and NMI408.case_detail_code = 'NMI408'
left join axxia01.dbo.casdet NMI409 WITH(NOLOCK) on NMI409.case_id = dim_matter_header_current.case_id and NMI409.case_detail_code = 'NMI409'
left join axxia01.dbo.casdet NMI410 WITH(NOLOCK) on NMI410.case_id = dim_matter_header_current.case_id and NMI410.case_detail_code = 'NMI410'

left join axxia01.dbo.casdet NMI636 WITH(NOLOCK) on NMI636.case_id = dim_matter_header_current.case_id and NMI636.case_detail_code = 'NMI636'
left join axxia01.dbo.casdet NMI637 WITH(NOLOCK) on NMI637.case_id = dim_matter_header_current.case_id and NMI637.case_detail_code = 'NMI637'
left join axxia01.dbo.casdet NMI638 WITH(NOLOCK) on NMI638.case_id = dim_matter_header_current.case_id and NMI638.case_detail_code = 'NMI638'
left join axxia01.dbo.casdet NMI639 WITH(NOLOCK) on NMI639.case_id = dim_matter_header_current.case_id and NMI639.case_detail_code = 'NMI639'
left join axxia01.dbo.casdet NMI640 WITH(NOLOCK) on NMI640.case_id = dim_matter_header_current.case_id and NMI640.case_detail_code = 'NMI640'
left join axxia01.dbo.casdet NMI641 WITH(NOLOCK) on NMI641.case_id = dim_matter_header_current.case_id and NMI641.case_detail_code = 'NMI641'
left join axxia01.dbo.casdet NMI642 WITH(NOLOCK) on NMI642.case_id = dim_matter_header_current.case_id and NMI642.case_detail_code = 'NMI642'
left join axxia01.dbo.casdet NMI643 WITH(NOLOCK) on NMI643.case_id = dim_matter_header_current.case_id and NMI643.case_detail_code = 'NMI643'
left join axxia01.dbo.casdet NMI644 WITH(NOLOCK) on NMI644.case_id = dim_matter_header_current.case_id and NMI644.case_detail_code = 'NMI644'
left join axxia01.dbo.casdet NMI645 WITH(NOLOCK) on NMI645.case_id = dim_matter_header_current.case_id and NMI645.case_detail_code = 'NMI645'
left join axxia01.dbo.casdet NMI646 WITH(NOLOCK) on NMI646.case_id = dim_matter_header_current.case_id and NMI646.case_detail_code = 'NMI646'
left join axxia01.dbo.casdet NMI647 WITH(NOLOCK) on NMI647.case_id = dim_matter_header_current.case_id and NMI647.case_detail_code = 'NMI647'
left join axxia01.dbo.casdet NMI648 WITH(NOLOCK) on NMI648.case_id = dim_matter_header_current.case_id and NMI648.case_detail_code = 'NMI648'
left join axxia01.dbo.casdet NMI649 WITH(NOLOCK) on NMI649.case_id = dim_matter_header_current.case_id and NMI649.case_detail_code = 'NMI649'
left join axxia01.dbo.casdet NMI650 WITH(NOLOCK) on NMI650.case_id = dim_matter_header_current.case_id and NMI650.case_detail_code = 'NMI650'
left join axxia01.dbo.casdet NMI651 WITH(NOLOCK) on NMI651.case_id = dim_matter_header_current.case_id and NMI651.case_detail_code = 'NMI651'
left join axxia01.dbo.casdet NMI652 WITH(NOLOCK) on NMI652.case_id = dim_matter_header_current.case_id and NMI652.case_detail_code = 'NMI652'
left join axxia01.dbo.casdet NMI653 WITH(NOLOCK) on NMI653.case_id = dim_matter_header_current.case_id and NMI653.case_detail_code = 'NMI653'
left join axxia01.dbo.casdet NMI654 WITH(NOLOCK) on NMI654.case_id = dim_matter_header_current.case_id and NMI654.case_detail_code = 'NMI654'
left join axxia01.dbo.casdet NMI655 WITH(NOLOCK) on NMI655.case_id = dim_matter_header_current.case_id and NMI655.case_detail_code = 'NMI655'
left join axxia01.dbo.casdet NMI656 WITH(NOLOCK) on NMI656.case_id = dim_matter_header_current.case_id and NMI656.case_detail_code = 'NMI656'
left join axxia01.dbo.casdet NMI657 WITH(NOLOCK) on NMI657.case_id = dim_matter_header_current.case_id and NMI657.case_detail_code = 'NMI657'
left join axxia01.dbo.casdet NMI658 WITH(NOLOCK) on NMI658.case_id = dim_matter_header_current.case_id and NMI658.case_detail_code = 'NMI658'
left join axxia01.dbo.casdet NMI659 WITH(NOLOCK) on NMI659.case_id = dim_matter_header_current.case_id and NMI659.case_detail_code = 'NMI659'
left join axxia01.dbo.casdet NMI660 WITH(NOLOCK) on NMI660.case_id = dim_matter_header_current.case_id and NMI660.case_detail_code = 'NMI660'
left join axxia01.dbo.casdet NMI661 WITH(NOLOCK) on NMI661.case_id = dim_matter_header_current.case_id and NMI661.case_detail_code = 'NMI661'
left join axxia01.dbo.casdet NMI662 WITH(NOLOCK) on NMI662.case_id = dim_matter_header_current.case_id and NMI662.case_detail_code = 'NMI662'
left join axxia01.dbo.casdet NMI663 WITH(NOLOCK) on NMI663.case_id = dim_matter_header_current.case_id and NMI663.case_detail_code = 'NMI663'
left join axxia01.dbo.casdet NMI664 WITH(NOLOCK) on NMI664.case_id = dim_matter_header_current.case_id and NMI664.case_detail_code = 'NMI664'
left join axxia01.dbo.casdet NMI665 WITH(NOLOCK) on NMI665.case_id = dim_matter_header_current.case_id and NMI665.case_detail_code = 'NMI665'

left join axxia01.dbo.casdet NMI892 WITH(NOLOCK) on NMI892.case_id = dim_matter_header_current.case_id and NMI892.case_detail_code = 'NMI892'
left join axxia01.dbo.casdet NMI893 WITH(NOLOCK) on NMI893.case_id = dim_matter_header_current.case_id and NMI893.case_detail_code = 'NMI893'
left join axxia01.dbo.casdet NMI894 WITH(NOLOCK) on NMI894.case_id = dim_matter_header_current.case_id and NMI894.case_detail_code = 'NMI894'
left join axxia01.dbo.casdet NMI895 WITH(NOLOCK) on NMI895.case_id = dim_matter_header_current.case_id and NMI895.case_detail_code = 'NMI895'
left join axxia01.dbo.casdet NMI896 WITH(NOLOCK) on NMI896.case_id = dim_matter_header_current.case_id and NMI896.case_detail_code = 'NMI896'
left join axxia01.dbo.casdet NMI897 WITH(NOLOCK) on NMI897.case_id = dim_matter_header_current.case_id and NMI897.case_detail_code = 'NMI897'
left join axxia01.dbo.casdet NMI898 WITH(NOLOCK) on NMI898.case_id = dim_matter_header_current.case_id and NMI898.case_detail_code = 'NMI898'
left join axxia01.dbo.casdet NMI899 WITH(NOLOCK) on NMI899.case_id = dim_matter_header_current.case_id and NMI899.case_detail_code = 'NMI899'
left join axxia01.dbo.casdet NMI900 WITH(NOLOCK) on NMI900.case_id = dim_matter_header_current.case_id and NMI900.case_detail_code = 'NMI900'
left join axxia01.dbo.casdet NMI901 WITH(NOLOCK) on NMI901.case_id = dim_matter_header_current.case_id and NMI901.case_detail_code = 'NMI901'
left join axxia01.dbo.casdet NMI902 WITH(NOLOCK) on NMI902.case_id = dim_matter_header_current.case_id and NMI902.case_detail_code = 'NMI902'
left join axxia01.dbo.casdet NMI903 WITH(NOLOCK) on NMI903.case_id = dim_matter_header_current.case_id and NMI903.case_detail_code = 'NMI903'
left join axxia01.dbo.casdet NMI904 WITH(NOLOCK) on NMI904.case_id = dim_matter_header_current.case_id and NMI904.case_detail_code = 'NMI904'
left join axxia01.dbo.casdet NMI905 WITH(NOLOCK) on NMI905.case_id = dim_matter_header_current.case_id and NMI905.case_detail_code = 'NMI905'
left join axxia01.dbo.casdet NMI906 WITH(NOLOCK) on NMI906.case_id = dim_matter_header_current.case_id and NMI906.case_detail_code = 'NMI906'

left join axxia01.dbo.casdet NMI358 WITH(NOLOCK) on NMI358.case_id = dim_matter_header_current.case_id and NMI358.case_detail_code = 'NMI358'
left join axxia01.dbo.casdet NMI350 WITH(NOLOCK) on NMI350.case_id = dim_matter_header_current.case_id and NMI350.case_detail_code = 'NMI350'
left join axxia01.dbo.casdet NMI356 WITH(NOLOCK) on NMI356.case_id = dim_matter_header_current.case_id and NMI356.case_detail_code = 'NMI356'
left join axxia01.dbo.casdet NMI352 WITH(NOLOCK) on NMI352.case_id = dim_matter_header_current.case_id and NMI352.case_detail_code = 'NMI352'
left join axxia01.dbo.casdet NMI354 WITH(NOLOCK) on NMI354.case_id = dim_matter_header_current.case_id and NMI354.case_detail_code = 'NMI354'
left join axxia01.dbo.casdet NMI359 WITH(NOLOCK) on NMI359.case_id = dim_matter_header_current.case_id and NMI359.case_detail_code = 'NMI359'
left join axxia01.dbo.casdet NMI351 WITH(NOLOCK) on NMI351.case_id = dim_matter_header_current.case_id and NMI351.case_detail_code = 'NMI351'
left join axxia01.dbo.casdet NMI357 WITH(NOLOCK) on NMI357.case_id = dim_matter_header_current.case_id and NMI357.case_detail_code = 'NMI357'
left join axxia01.dbo.casdet NMI363 WITH(NOLOCK) on NMI363.case_id = dim_matter_header_current.case_id and NMI363.case_detail_code = 'NMI363'
left join axxia01.dbo.casdet NMI370 WITH(NOLOCK) on NMI370.case_id = dim_matter_header_current.case_id and NMI370.case_detail_code = 'NMI370'


WHERE  dim_matter_header_current.matter_number <> 'ML' and  
ISNULL(LTRIM(RTRIM(outcome_of_case)),'') <> 'Exclude from reports' and
dim_matter_header_current.client_code in ('00215267', '00046018', 'C15332','C1001')
AND (date_closed_case_management IS NULL OR date_closed_case_management > @ClosedDate)

ORDER BY dim_matter_header_current.client_code,dim_matter_header_current.matter_number

--select distinct 
--client,
--matter,
--Structure.KnownAs + ' ' + Structure.Surname Name,
--Structure.team,
--worktype.ds_descrn,
--camatgrp.mg_wrktyp,
--cashdr.date_opened,
--cashdr.date_closed,
--FTR087.case_date FTR087,
--TRA068.case_text [outcome],
--TRA086.case_date [Date damages settled],   
--NMI065.case_value [A) Interim damages payments (post instruction)],               
--NMI353.case_date [Date of second interim damages payment],
--NMI360.case_Value [Amount of first interim damages payment],
--NMI361.case_date [Date of first interim damages payment],
--NMI362.case_Value [Amount of second interim damages payment],
--NMI364.case_Value [Amount of third interim damages payment],
--NMI365.case_date [Date of third interim damages payment],
--NMI366.case_Value [Amount of fourth interim damages payment],
--NMI367.case_date [Date of fourth interim damages payment],
--NMI368.case_Value [Amount of fifth interim damages payment],
--NMI369.case_date [Date of fifth interim damages payment],
--NMI406.case_text [Reason for first interim damages payment],
--NMI407.case_text [Reason for second interim damages payment],
--NMI408.case_text [Reason for third interim damages payment],
--NMI409.case_text [Reason for fourth interim damages payment],
--NMI410.case_text [Reason for fifth interim damages payment],
--NMI636.case_date [Date of sixth interim damages payment],
--NMI637.case_text [Reason for sixth interim damages payment],
--NMI638.case_Value [Amount of seventh interim damages payment],
--NMI639.case_date [Date of seventh interim damages payment],
--NMI640.case_text [Reason for seventh interim damages payment],
--NMI641.case_Value [Amount of eighth interim damages payment],
--NMI642.case_date [Date of eighth interim damages payment],
--NMI643.case_text [Reason for eighth interim damages payment],
--NMI644.case_Value [Amount of ninth interim damages payment],
--NMI645.case_date [Date of ninth interim damages payment],
--NMI646.case_text [Reason for ninth interim damages payment],
--NMI647.case_Value [Amount of tenth interim damages payment],
--NMI648.case_date [Date of tenth interim damages payment],
--NMI649.case_text [Reason for tenth interim damages payment],
--NMI650.case_Value [Amount of sixth interim damages payment],
--NMI651.case_Value [Amount of eleventh interim damages payment],
--NMI652.case_date [Date of eleventh interim damages payment],
--NMI653.case_text [Reason for eleventh interim damages payment],
--NMI654.case_Value [Amount of twelfth interim damages payment],
--NMI655.case_date [Date of twelfth interim damages payment],
--NMI656.case_text [Reason for twelfth interim damages payment],
--NMI657.case_Value [Amount of thirteenth interim damages payment],
--NMI658.case_date [Date of thirteenth interim damages payment],
--NMI659.case_text [Reason for thirteenth interim damages payment],
--NMI660.case_Value [Amount of fourteenth interim damages payment],
--NMI661.case_date [Date of fourteenth interim damages payment],
--NMI662.case_text [Reason for fourteenth interim damages payment],
--NMI663.case_Value [Amount of fifteenth interim damages payment],
--NMI664.case_date [Date of fifteenth interim damages payment],
--NMI665.case_text [Reason for fifteenth interim damages payment],
--NMI892.case_Value [Amount of sixteenth interim damages payment],
--NMI893.case_date [Date of sixteenth interim damages payment],
--NMI894.case_text [Reason for sixteenth interim damages payment],
--NMI895.case_Value [Amount of seventeenth interim damages payment],
--NMI896.case_date [Date of seventeenth interim damages payment],
--NMI897.case_text [Reason for seventeenth interim damages payment],
--NMI898.case_Value [Amount of eighteenth interim damages payment],
--NMI899.case_date [Date of eighteenth interim damages payment],
--NMI900.case_text [Reason for eighteenth interim damages payment],
--NMI901.case_Value [Amount of nineteenth interim damages payment],
--NMI902.case_date [Date of nineteenth interim damages payment],
--NMI903.case_text [Reason for nineteenth interim damages payment],
--NMI904.case_Value [Amount of twentieth interim damages payment],
--NMI905.case_date [Date of twentieth interim damages payment],
--NMI906.case_text [Reason for twentieth interim damages payment],

--NMI066.case_value [A) Interim costs payments (post instruction)], 
--NMI358.case_value [Amount of fifth interim costs payment],
--NMI350.case_value [Amount of first interim costs payment],
--NMI356.case_value [Amount of fourth interim costs payment],
--NMI352.case_value [Amount of second interim costs payment],
--NMI354.case_value [Amount of third interim costs payment],
--NMI359.case_date [Date of fifth interim costs payment],
--NMI351.case_date [Date of first interim costs payment],
--NMI357.case_date [Date of fourth interim costs payment],
--NMI363.case_date [Date of second interim costs payment],
--NMI370.case_date [Date of third interim costs payment]


--from axxia01.dbo.cashdr
--left join axxia01.dbo.camatgrp on client= mg_client and mg_matter = matter
--left join axxia01.dbo.casdet NMI066 on NMI066.case_id = cashdr.case_id and NMI066.case_detail_code = 'NMI066'
--left join axxia01.dbo.casdet NMI065 on NMI065.case_id = cashdr.case_id and NMI065.case_detail_code = 'NMI065'

--left join axxia01.dbo.casdet NMI353 on NMI353.case_id = cashdr.case_id and NMI353.case_detail_code = 'NMI353'
--left join axxia01.dbo.casdet NMI360 on NMI360.case_id = cashdr.case_id and NMI360.case_detail_code = 'NMI360'    
--left join axxia01.dbo.casdet NMI361 on NMI361.case_id = cashdr.case_id and NMI361.case_detail_code = 'NMI361'
--left join axxia01.dbo.casdet NMI362 on NMI362.case_id = cashdr.case_id and NMI362.case_detail_code = 'NMI362'
--left join axxia01.dbo.casdet NMI364 on NMI364.case_id = cashdr.case_id and NMI364.case_detail_code = 'NMI364'
--left join axxia01.dbo.casdet NMI365 on NMI365.case_id = cashdr.case_id and NMI365.case_detail_code = 'NMI365'
--left join axxia01.dbo.casdet NMI366 on NMI366.case_id = cashdr.case_id and NMI366.case_detail_code = 'NMI366'
--left join axxia01.dbo.casdet NMI367 on NMI367.case_id = cashdr.case_id and NMI367.case_detail_code = 'NMI367'
--left join axxia01.dbo.casdet NMI368 on NMI368.case_id = cashdr.case_id and NMI368.case_detail_code = 'NMI368'
--left join axxia01.dbo.casdet NMI369 on NMI369.case_id = cashdr.case_id and NMI369.case_detail_code = 'NMI369'


--left join axxia01.dbo.casdet NMI406 on NMI406.case_id = cashdr.case_id and NMI406.case_detail_code = 'NMI406'
--left join axxia01.dbo.casdet NMI407 on NMI407.case_id = cashdr.case_id and NMI407.case_detail_code = 'NMI407'
--left join axxia01.dbo.casdet NMI408 on NMI408.case_id = cashdr.case_id and NMI408.case_detail_code = 'NMI408'
--left join axxia01.dbo.casdet NMI409 on NMI409.case_id = cashdr.case_id and NMI409.case_detail_code = 'NMI409'
--left join axxia01.dbo.casdet NMI410 on NMI410.case_id = cashdr.case_id and NMI410.case_detail_code = 'NMI410'

--left join axxia01.dbo.casdet NMI636 on NMI636.case_id = cashdr.case_id and NMI636.case_detail_code = 'NMI636'
--left join axxia01.dbo.casdet NMI637 on NMI637.case_id = cashdr.case_id and NMI637.case_detail_code = 'NMI637'
--left join axxia01.dbo.casdet NMI638 on NMI638.case_id = cashdr.case_id and NMI638.case_detail_code = 'NMI638'
--left join axxia01.dbo.casdet NMI639 on NMI639.case_id = cashdr.case_id and NMI639.case_detail_code = 'NMI639'
--left join axxia01.dbo.casdet NMI640 on NMI640.case_id = cashdr.case_id and NMI640.case_detail_code = 'NMI640'
--left join axxia01.dbo.casdet NMI641 on NMI641.case_id = cashdr.case_id and NMI641.case_detail_code = 'NMI641'
--left join axxia01.dbo.casdet NMI642 on NMI642.case_id = cashdr.case_id and NMI642.case_detail_code = 'NMI642'
--left join axxia01.dbo.casdet NMI643 on NMI643.case_id = cashdr.case_id and NMI643.case_detail_code = 'NMI643'
--left join axxia01.dbo.casdet NMI644 on NMI644.case_id = cashdr.case_id and NMI644.case_detail_code = 'NMI644'
--left join axxia01.dbo.casdet NMI645 on NMI645.case_id = cashdr.case_id and NMI645.case_detail_code = 'NMI645'
--left join axxia01.dbo.casdet NMI646 on NMI646.case_id = cashdr.case_id and NMI646.case_detail_code = 'NMI646'
--left join axxia01.dbo.casdet NMI647 on NMI647.case_id = cashdr.case_id and NMI647.case_detail_code = 'NMI647'
--left join axxia01.dbo.casdet NMI648 on NMI648.case_id = cashdr.case_id and NMI648.case_detail_code = 'NMI648'
--left join axxia01.dbo.casdet NMI649 on NMI649.case_id = cashdr.case_id and NMI649.case_detail_code = 'NMI649'
--left join axxia01.dbo.casdet NMI650 on NMI650.case_id = cashdr.case_id and NMI650.case_detail_code = 'NMI650'
--left join axxia01.dbo.casdet NMI651 on NMI651.case_id = cashdr.case_id and NMI651.case_detail_code = 'NMI651'
--left join axxia01.dbo.casdet NMI652 on NMI652.case_id = cashdr.case_id and NMI652.case_detail_code = 'NMI652'
--left join axxia01.dbo.casdet NMI653 on NMI653.case_id = cashdr.case_id and NMI653.case_detail_code = 'NMI653'
--left join axxia01.dbo.casdet NMI654 on NMI654.case_id = cashdr.case_id and NMI654.case_detail_code = 'NMI654'
--left join axxia01.dbo.casdet NMI655 on NMI655.case_id = cashdr.case_id and NMI655.case_detail_code = 'NMI655'
--left join axxia01.dbo.casdet NMI656 on NMI656.case_id = cashdr.case_id and NMI656.case_detail_code = 'NMI656'
--left join axxia01.dbo.casdet NMI657 on NMI657.case_id = cashdr.case_id and NMI657.case_detail_code = 'NMI657'
--left join axxia01.dbo.casdet NMI658 on NMI658.case_id = cashdr.case_id and NMI658.case_detail_code = 'NMI658'
--left join axxia01.dbo.casdet NMI659 on NMI659.case_id = cashdr.case_id and NMI659.case_detail_code = 'NMI659'
--left join axxia01.dbo.casdet NMI660 on NMI660.case_id = cashdr.case_id and NMI660.case_detail_code = 'NMI660'
--left join axxia01.dbo.casdet NMI661 on NMI661.case_id = cashdr.case_id and NMI661.case_detail_code = 'NMI661'
--left join axxia01.dbo.casdet NMI662 on NMI662.case_id = cashdr.case_id and NMI662.case_detail_code = 'NMI662'
--left join axxia01.dbo.casdet NMI663 on NMI663.case_id = cashdr.case_id and NMI663.case_detail_code = 'NMI663'
--left join axxia01.dbo.casdet NMI664 on NMI664.case_id = cashdr.case_id and NMI664.case_detail_code = 'NMI664'
--left join axxia01.dbo.casdet NMI665 on NMI665.case_id = cashdr.case_id and NMI665.case_detail_code = 'NMI665'

--left join axxia01.dbo.casdet NMI892 on NMI892.case_id = cashdr.case_id and NMI892.case_detail_code = 'NMI892'
--left join axxia01.dbo.casdet NMI893 on NMI893.case_id = cashdr.case_id and NMI893.case_detail_code = 'NMI893'
--left join axxia01.dbo.casdet NMI894 on NMI894.case_id = cashdr.case_id and NMI894.case_detail_code = 'NMI894'
--left join axxia01.dbo.casdet NMI895 on NMI895.case_id = cashdr.case_id and NMI895.case_detail_code = 'NMI895'
--left join axxia01.dbo.casdet NMI896 on NMI896.case_id = cashdr.case_id and NMI896.case_detail_code = 'NMI896'
--left join axxia01.dbo.casdet NMI897 on NMI897.case_id = cashdr.case_id and NMI897.case_detail_code = 'NMI897'
--left join axxia01.dbo.casdet NMI898 on NMI898.case_id = cashdr.case_id and NMI898.case_detail_code = 'NMI898'
--left join axxia01.dbo.casdet NMI899 on NMI899.case_id = cashdr.case_id and NMI899.case_detail_code = 'NMI899'
--left join axxia01.dbo.casdet NMI900 on NMI900.case_id = cashdr.case_id and NMI900.case_detail_code = 'NMI900'
--left join axxia01.dbo.casdet NMI901 on NMI901.case_id = cashdr.case_id and NMI901.case_detail_code = 'NMI901'
--left join axxia01.dbo.casdet NMI902 on NMI902.case_id = cashdr.case_id and NMI902.case_detail_code = 'NMI902'
--left join axxia01.dbo.casdet NMI903 on NMI903.case_id = cashdr.case_id and NMI903.case_detail_code = 'NMI903'
--left join axxia01.dbo.casdet NMI904 on NMI904.case_id = cashdr.case_id and NMI904.case_detail_code = 'NMI904'
--left join axxia01.dbo.casdet NMI905 on NMI905.case_id = cashdr.case_id and NMI905.case_detail_code = 'NMI905'
--left join axxia01.dbo.casdet NMI906 on NMI906.case_id = cashdr.case_id and NMI906.case_detail_code = 'NMI906'

--left join axxia01.dbo.casdet NMI358 on NMI358.case_id = cashdr.case_id and NMI358.case_detail_code = 'NMI358'
--left join axxia01.dbo.casdet NMI350 on NMI350.case_id = cashdr.case_id and NMI350.case_detail_code = 'NMI350'
--left join axxia01.dbo.casdet NMI356 on NMI356.case_id = cashdr.case_id and NMI356.case_detail_code = 'NMI356'
--left join axxia01.dbo.casdet NMI352 on NMI352.case_id = cashdr.case_id and NMI352.case_detail_code = 'NMI352'
--left join axxia01.dbo.casdet NMI354 on NMI354.case_id = cashdr.case_id and NMI354.case_detail_code = 'NMI354'
--left join axxia01.dbo.casdet NMI359 on NMI359.case_id = cashdr.case_id and NMI359.case_detail_code = 'NMI359'
--left join axxia01.dbo.casdet NMI351 on NMI351.case_id = cashdr.case_id and NMI351.case_detail_code = 'NMI351'
--left join axxia01.dbo.casdet NMI357 on NMI357.case_id = cashdr.case_id and NMI357.case_detail_code = 'NMI357'
--left join axxia01.dbo.casdet NMI363 on NMI363.case_id = cashdr.case_id and NMI363.case_detail_code = 'NMI363'
--left join axxia01.dbo.casdet NMI370 on NMI370.case_id = cashdr.case_id and NMI370.case_detail_code = 'NMI370'

--left join axxia01.dbo.casdet TRA086 on TRA086.case_id = cashdr.case_id and TRA086.case_detail_code = 'TRA086'
--left join axxia01.dbo.casdet FTR087 on FTR087.case_id = cashdr.case_id and FTR087.case_detail_code = 'FTR087'
--left join axxia01.dbo.casdet TRA068 on TRA068.case_id = cashdr.case_id and TRA068.case_detail_code = 'TRA068'
--left join Exceptions.Accounts.Structure on Structure.feeearnercode = mg_feearn 

--left join  axxia01.dbo.cadescrp  worktype on worktype.ds_reckey = mg_wrktyp and ds_rectyp = 'WT'

--where 
--matter <> 'ML' and  
--ISNULL(LTRIM(RTRIM(TRA068.case_text)),'') <> 'Exclude from reports' and
--client in ('00215267', '00046018', 'C15332','C1001') 
----and 
----date_opened < @EndtDate and 
----	(
----		date_closed >= @StartDate or date_closed is NULL
----	) and 
----	(
----		FTR087.case_date >= @StartDate or FTR087.case_date is NULL
----	)

--AND (date_closed IS NULL OR date_closed > @ClosedDate)

--ORDER by client, matter
GO
