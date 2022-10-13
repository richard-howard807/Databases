SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 11-03-2019
-- Description:	Zurich Outsource Quarterly Summary
-- =============================================
CREATE PROCEDURE [dbo].[ZurichOutsourceQuarterlySummaryDCO]-- 2019
	-- Add the parameters for the stored procedure here
	@year as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--DECLARE @year AS int = 2019

IF OBJECT_ID('tempdb..#raw_data','U') IS NOT NULL
DROP TABLE #raw_data
IF OBJECT_ID('tempdb..#filtered_data','U') IS NOT NULL
DROP TABLE #filtered_data
IF OBJECT_ID('tempdb..#results','U') IS NOT NULL
DROP TABLE #results

---------------------------------Raw Data-----------------------------------------
SELECT 
fee_billed_by_panel,
zurich_own_disbursements,
fact_dimension_main.client_code
,fact_dimension_main.matter_number
,RTRIM(WPS275) [Zurich claim number]
,RTRIM(zurich_instruction_type) zurich_instruction_type
,dim_detail_core_details.[date_instructions_received]
,ISNULL(WPS386,date_settlement_form_sent_to_zurich) [date_settlement_form_sent_to_zurich]
,CASE
			WHEN WPS387 IS NOT NULL THEN RTRIM(WPS387)
           WHEN dim_detail_critical_mi.[claim_status] IS NULL THEN
               'Open'
           WHEN dim_detail_critical_mi.[claim_status] IN ( 'Re-opened', 'Re-Opened' ) THEN
               'Open'
           ELSE
               RTRIM(dim_detail_critical_mi.[claim_status])
           END Claimstatus
, CASE 
	   WHEN try_cast(date_reopened_5 AS date) IS NOT null THEN CONVERT(NVARCHAR(max),convert(datetime,date_reopened_5,101),101)
	   WHEN try_cast(date_reopened_4 AS date) IS NOT NULL THEN CONVERT(NVARCHAR(max),convert(datetime,date_reopened_4,101),101)
	   WHEN try_cast(date_reopened_3 AS date) IS NOT null THEN CONVERT(NVARCHAR(max),convert(datetime,date_reopened_3,101),101)
	   WHEN try_cast(date_reopened_2 AS date) IS NOT null THEN CONVERT(NVARCHAR(max),convert(datetime,date_reopened_2,101),101)
	   WHEN try_cast(date_reopened_1 AS date) IS NOT NULL THEN CONVERT(NVARCHAR(max),convert(datetime,date_reopened_1,101),101)
	   ELSE CONVERT(NVARCHAR(MAX),dim_detail_critical_mi.[date_reopened],101)	END [date_reopened]
,date_closed_case_management
,UPPER(RTRIM(dim_detail_litigation.are_weightmans_on_the_court_record)) AS [Litigated]
,ISNULL(total_paid,0) total_paid
,general_damages_paid
,special_damages_paid
,fraud_savings
,CASE WHEN dim_detail_claim.[reason_for_reopening_request] = 'Closed in error by panel' THEN 'Yes' ELSE 'No' END [Re_opening_avoidable]
,was_litigation_avoidable
,WPS332 [WPS332_category]
INTO #raw_data
FROM red_dw.dbo.fact_dimension_main
    left JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    left JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
    left JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT JOIN red_Dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
	LEFT JOIN red_Dw.dbo.dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
	LEFT JOIN red_Dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN
    (
        
      SELECT 
dim_parent_detail.client_code,
dim_parent_detail.matter_number,
dim_parent_detail.dim_parent_key,
zurich_rsa_claim_number WPS275,
lead_follow WPS276,
SUM(current_reserve) WPS277,
SUM(general_damages_paid) WPS278,
SUM(special_damages_paid) WPS279,
SUM(claimants_costs_paid) WPS280,
SUM(cru_paid) WPS281,
SUM(monies_recovered_if_applicable)  WPS282,
SUM(our_proportion_per_of_damages) WPS283,
SUM(our_proportion_per_of_costs) WPS284,
SUM(fee_billed_by_panel) WPS340,
SUM(own_disbursements) WPS341,
policy_holder_name_of_insured  WPS344,
wp_type WPS332,
mfu WPS335,
date_settlement_form_sent_to_zurich WPS386,
claim_status WPS387
					   FROM red_Dw.dbo.dim_parent_detail

       LEFT JOIN red_Dw.dbo.dim_child_detail ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
	   LEFT JOIN red_dw.dbo.fact_child_detail ON fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key       
	    WHERE dim_parent_detail.client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' )
		GROUP BY dim_parent_detail.client_code,
dim_parent_detail.matter_number,
dim_parent_detail.dim_parent_key,
zurich_rsa_claim_number,
lead_follow ,

policy_holder_name_of_insured,
wp_type ,
mfu ,
date_settlement_form_sent_to_zurich ,
claim_status 
				
				
    ) AS ClaimDetails
        ON RTRIM(fact_dimension_main.client_code) = RTRIM(ClaimDetails.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(ClaimDetails.matter_number)
WHERE (
		(
          red_dw.dbo.fact_dimension_main.client_code IN ( 'Z1001','Z00002', 'Z00004', 'Z00018', 'Z00014' )
		  or		  
			red_dw.dbo.dim_matter_header_current.case_id IN 
			(22358,25009,20520,20691,20916,23882,21282,
									21380,24414,25488,24735,21367,21361,21602,
									24893,21867,23579,22159,22500,22245,22321
								   ,374091,395458,406599,410799,415781,415815
									,382964,389385,393324,411937)
									)
         
             AND dim_detail_client.[zurich_instruction_type] LIKE 'Outsource%'
             AND dim_detail_client.[zurich_instruction_type] <> 'Outsource - Mesothelioma'
      
      AND reporting_exclusions =0
      AND
      (
          dim_detail_client.[zurich_data_admin_exclude_from_reports] = 'No'
          OR dim_detail_client.[zurich_data_admin_exclude_from_reports] IS NULL
      )
	  		OR ms_fileid IN (
		4867697,4867731,4867770,4867821,4867837,4867868,4867866,4867886,4867910,4867963,4867965,4867983,4867986,4875783,4867970,4867814,4867843,4867846,4867891,4867844,4867681,4880231,4872876,4872946,4872978,4846633,4880416,4880569,4880623,4873223,4880692,4889902,4859810,4885808,4885809,4885810,4885824,4885811,4885818,4885919,
		4885920,4885921,4885922,4885923,4885924,4885925,4885926,4885927,4885928,4885819,4885930,4885931,4885932,4885933,4885934,4885935,4885936,4885937,4885938,4885939,4885820,4885942,4885943,4885944,4885945,4885946,4885947,4885948,4885949,4885952,4885953,4885954,4885955,4885956,4885957,4885958,4885959,4885960,4885961,4885822,
		4885963,4885964,4885965,4885966,4885967,4885968,4885969,4885970,4885971,4885972,4885823,4885975,4885977,4885978,4885979,4885980,4885981,4885982,4885983,4885984,4885986,4885987,4885988,4885989,4885990,4885991,4885992,4885993,4885994,4885995,4885825,4885997,4885998,4885999,4886000,4886001,4886002,4886003,4886004,4886005,
		4886006,4885826,4886008,4886009,4886010,4886011,4886012,4886013,4886014,4886015,4886016,4886017,4885827,4886019,4886020,4886021,4886022,4886023,4886024,4886025,4886026,4886027,4886028,4885829,4886030,4886031,4886032,4886033,4886034,4886035,4886036,4886037,4886038,4886039,4885830,4886041,4886042,4886043,4886044,4886045,
		4886046,4886047,4886048,4886049,4886050,4886052,4886053,4886054,4886055,4886056,4886059,4886060,4886061,4886063,4886064,4886065,4886066,4886067,4886068,4886069,4886070,4886071,4886072,4885833,4886074,4886075,4886076,4886077,4886078,4886079,4886080,4886081,4886082,4886083,4885834,4885836,4885837,4885841,4885843,4885844,
		4885845,4885846,4885847,4885848,4885849,4885851,4885852,4885854,4885855,4885856,4885857,4885858,4885859,4885860,4885812,4885864,4885865,4885866,4885867,4885868,4885869,4885870,4885871,4885872,4885873,4885813,4885875,4885876,4885877,4885878,4885879,4885880,4885881,4885882,4885883,4885884,4885814,4885886,4885888,4885889,
		4885890,4885891,4885892,4885893,4885894,4885895,4885897,4885898,4885900,4885901,4885902,4885903,4885904,4885905,4885906,4885908,4885909,4885910,4885911,4885912,4885913,4885914,4885915,4885916,4885917,4885821,4886057,4886086,4886087,4886088,4886089,4886090,4886091,4886092,4886093,4886094,4886095,4886097,4886098,4886099,
		4886100,4886101,4886103,4886104,4886105,4886108,4886109,4886110,4886111,4886112,4886113,4886114,4886115,4886116,4886117,4886119,4886120,4886121,4886122,4886123,4886124,4886125,4886126,4886127,4886128,4886130,4886131,4886132,4886133,4886134,4886135,4886136,4886137,4886138,4886142,4886144,4886145,4886146,4886147,4886148,
		4886149,4886150,4886152,4886153,4886154,4886155,4886157,4886158,4886159,4886160,4886163,4886164,4886165,4886166,4886167,4886169,4886170,4886172,4886174,4886175,4886176,4886177,4886178,4886179,4886180,4886181,4886182,4886183,4886185,4886186,4886187,4886188,4886189,4886190,4886191,4886192,4886193,4886194,4886197,4886198,
		4886199,4886200,4886201,4886202,4886203,4886204,4886205,4886206,4886208,4886209,4886210,4886211,4886212,4886213,4886215,4886216,4886217,4886219,4886220,4886221,4886222,4886223,4886224,4886225,4886226,4886227,4886228,4886230,4886231,4886232,4886233,4886234,4886235,4886236,4886237,4886238,4886239,4886241,4886242,4886243,
		4886245,4886246,4886247,4886248,4886252,4886253,4886254,4886255,4886256,4886257,4886258,4886259,4886260,4886261,4886263,4886264,4886265,4886266,4886267,4886268,4886269,4886270,4886271,4886272,4886275,4886276,4886277,4886278,4886279,4886280,4886281,4886282,4886285,4886290,4886058,4886161,4860926,4886214,4886288,4886289,
		4886291,4886294,4886292,4886293,4886310,4886311,4886326,4886312,4886313,4886323,4886314,4886315,4886316,4886317,4886319,4886321,4886322,4886320,4886324,4886327,4886328,4886330,4886331,4886332,4886333,4886334,4886325,4886343,4886335,4886336,4886337,4886338,4886339,4886344,4886341,4886345,4886342,4886346,4886347,4886348,
		4886349,4886350,4886352,4886353,4886354,4886355,4886356,4886357,4886358,4886359,4886360,4886361,4886363,4886364,4886365,4886366,4886367,4886368,4886369,4886370,4886371,4886372,4886374,4886375,4886376,4886377,4886378,4886379,4886380,4886381,4886391,4862112,4886382,4886383,4886385,4886386,4886387,4886388,4886389,4886390,
		4886392,4886393,4886394,4886397,4886398,4886399,4886400,4886401,4886402,4886403,4886404,4886405,4886407,4886408,4886410,4886411,4886412,4886419,4886413,4886415,4886414,4886416,4886420,4886421,4886422,4886423,4886424,4886426,4886427,4886428,4886425,4886430,4886435,4886431,4886432,4886433,4886436,4886437,4886438,4886439,
		4886441,4886442,4886443,4886444,4886445,4886446,4886447,4886448,4886449,4886450,4886453,4886454,4886461,4886455,4886456,4886457,4886458,4886459,4886460,4886463,4886464,4886466,4886467,4886465,4886468,4886469,4886470,4886471,4886472,4886474,4886475,4886476,4886477,4886478,4886479,4886480,4886481,4886483,4886482,4886485,
		4886486,4886487,4886488,4886489,4886490,4886491,4886492,4886493,4886494,4886496,4886498,4886497,4886499,4886500,4886501,4886502,4886503,4886504,4886505,4886507,4886508,4886509,4886510,4886511,4886512,4886514,4886515,4886516,4886518,4886519,4886520,4886521,4886522,4886523,4886524,4886525,4886526,4886527,4886530,4886531,
		4886532,4886533,4886534,4886535,4886536,4886537,4886538,4886539,4886542,4886543,4886544,4886545,4886546,4886547,4886548,4886549,4886550,4886552,4886553,4886554,4886555,4886556,4886557,4886558,4886559,4886560,4886561,4886563,4886564,4886565,4886566,4886567,4886568,4886569,4886570,4886571,4886572,4886574,4886578,4886575,
		4886576,4886577,4886579,4886580,4886581,4886582,4886583,4886585,4886586,4886587,4886588,4886589,4886590,4886591,4886596,4886592,4886593,4886594,4886597,4886598,4886599,4886600,4886601,4886602,4886603,4886604,4886605,4886607,4886608,4886609,4886610,4886612,4886611,4886613,4886614,4886615,4886616,4886618,4886619,4886620,
		4886621,4886622,4886623,4886624,4981851,4984089,4985408,4886002,4859922,4849998,4861830,4886061,4886336,4865908,4860354)
		
		)  AND 
	ISNULL(WPS332,'') <> 'MMI' 
AND ISNULL(WPS387,'') <> 'Cancelled'
AND ISNULL(zurich_instruction_type,'') IN ('Outsource - Coats','Outsource - NIHL','Outsource - HAVS')
--AND date_instructions_received >= '2019-01-01' AND date_instructions_received < '2019-04-01 00:00:00.000'

---------------------------------Filtered Data-----------------------------------------
SELECT 
client_code,
matter_number,
zurich_instruction_type,
date_instructions_received,
Received.cal_quarter_no,
Received.cal_month,
CASE WHEN zurich_instruction_type IN ('Outsource - Coats','Outsource - NIHL','Outsource - HAVS') AND Claimstatus <> 'Cancelled' THEN 1 else 0 END [volume_of_new_claims]
INTO #filtered_data
FROM 
#raw_data 
	LEFT JOIN red_Dw.dbo.dim_date Received ON Received.calendar_date = [date_instructions_received]		 
---------------------------------Case statments----------------------------------------

SELECT * INTO #results FROM (
select  
SUM(ISNULL([Outsource - NIHL],0)) [Outsource - NIHL],
SUM(ISNULL([Outsource - Coats],0)) [Outsource - Coats] ,
SUM(ISNULL([Outsource - HAVS],0)) [Outsource - HAVS] ,
cal_month,
MONTH(date_instructions_received) month,
year(date_instructions_received) year from #filtered_data

pivot (SUM([volume_of_new_claims]) for zurich_instruction_type in ([Outsource - NIHL],[Outsource - Coats],[Outsource - HAVS])) as AvgIncomePerDay
GROUP BY cal_month, MONTH(date_instructions_received) ,
year(date_instructions_received)  

) results
WHERE year >= @year-1 AND year  <= @year
ORDER BY year,month

SELECT
CAST(cal_year AS nvarchar(MAX)) + '/'+ CAST(cal_month_no    as  nvarchar(MAX)) [month_jamie],
daysinmonth.cal_month,
daysinmonth.cal_month_no,
daysinmonth,
#results.[Outsource - NIHL],
#results.[Outsource - Coats],
#results.[Outsource - HAVS]
FROM  (SELECT cal_month,cal_year, cal_month_name, cal_month_no,MAX(cal_day_in_month) daysinmonth from red_Dw.dbo.dim_date 
WHERE cal_year >= @year-1 AND cal_year  <= @year

GROUP BY cal_year, cal_month, cal_month_name, cal_month_no) daysinmonth
LEFT JOIN #results ON #results.cal_month = daysinmonth.cal_month







END
GO
