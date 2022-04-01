SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	20170928 LD Added additional payor columns
	10-01-2018 JL Added in join for HSD and team manager 1.1

*/



CREATE PROC [dbo].[AllDebtDump] AS 

/*
	Ticket #46913 - altered by Jamie Bonner 11/02/20 
	Insurer Client Reference column to look at client_reference if insurer_client_reference is blank
	Ticket #116880 - JB 05/10/2021 - added claim reference on invoice column
*/

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #outsource_mmi_claim_refs
--======================================================================================================================================================
-- Ticket #78621 - table to get MMI claim references from Zurich Disease Matters 2019 report
-- New MMI rules re bill payment means we need to identify outsource MMI claim refs on this report
--======================================================================================================================================================
SELECT DISTINCT
	LTRIM(RTRIM(WPS275)) [mmi_claim_number]
INTO #outsource_mmi_claim_refs
FROM red_dw.dbo.fact_dimension_main
    LEFT OUTER JOIN red_dw.dbo.dim_detail_client
        ON fact_dimension_main.client_code = dim_detail_client.client_code
           AND dim_detail_client.matter_number = fact_dimension_main.matter_number
    INNER JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.client_code = fact_dimension_main.client_code
           AND dim_matter_header_current.matter_number = fact_dimension_main.matter_number
    LEFT OUTER JOIN
     (
        
        SELECT Parent.client_code,
               Parent.matter_number,
               Parent.dim_parent_key,
               ROW_NUMBER() OVER (PARTITION BY Parent.client_code,
                                               Parent.matter_number
                                  ORDER BY Parent.client_code,
                                           Parent.matter_number,
                                           Parent.dim_parent_key ASC 
                                 ) AS xorder,
               WPS275,
               WPS332
        FROM

         (
            SELECT client_code,
                   matter_number,                   
                   MAX(dim_parent_key) dim_parent_key,
				   zurich_rsa_claim_number AS WPS275
            FROM red_dw.dbo.dim_parent_detail
            WHERE client_code in ('Z00004', 'Z00018', 'Z1001')
			GROUP BY client_code,
                   matter_number,
				   zurich_rsa_claim_number
        ) AS Parent
	    LEFT OUTER JOIN 
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       wp_type AS WPS332
                FROM red_dw.dbo.dim_child_detail
            ) AS dim_child
              ON Parent.dim_parent_key = dim_child.dim_parent_key
    ) AS ClaimDetails
        ON RTRIM(fact_dimension_main.client_code) = RTRIM(ClaimDetails.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(ClaimDetails.matter_number)
    
WHERE
	RTRIM(WPS332) = 'MMI'
	AND (
		red_dw.dbo.fact_dimension_main.client_code IN ( 'Z1001','Z00004', 'Z00018')
		AND dim_detail_client.[zurich_instruction_type] LIKE 'Outsource%'
		AND dim_detail_client.[zurich_instruction_type] <> 'Outsource - Mesothelioma' 
		AND reporting_exclusions =0
		AND (
				dim_detail_client.[zurich_data_admin_exclude_from_reports] = 'No'
				OR dim_detail_client.[zurich_data_admin_exclude_from_reports] IS NULL
			)
		-- zurich ref not deleted from MS
		AND (WPS275 IN (SELECT txtClaimNum COLLATE Latin1_General_BIN FROM MS_Prod..udClaimsClNumber 
			WHERE fileID =   dim_matter_header_current.ms_fileid)
			OR WPS275 IS NULL
			OR ms_only = 0
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
			 -- zurich ref not deleted from MS
		AND (WPS275 in (SELECT txtClaimNum COLLATE Latin1_General_BIN FROM MS_Prod..udClaimsClNumber 
			WHERE fileID =  dim_matter_header_current.ms_fileid)
			OR WPS275 IS NULL
			OR ms_only = 0
			)
		
		)
				
--======================================================================================================================================================



SELECT 
	master_client.client_partner_name AS 'master_client_partner',
	ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber) AS 'Client',
	ISNULL(RIGHT(Matter.loadnumber, LEN(Matter.loadnumber) - CHARINDEX('-',Matter.loadnumber))
	,
	RIGHT(Matter.altnumber, LEN(Matter.altnumber) - CHARINDEX('-',Matter.altnumber))
	) AS 'Matter', 
	Matter.Number AS '3e ref',
	dim_fed_hierarchy_history.hierarchylevel2hist AS 'BusinessLine',
	dim_fed_hierarchy_history.hierarchylevel3hist AS 'PracticeArea',
	dim_fed_hierarchy_history.hierarchylevel4hist AS 'Team',
	dim_matter_header_current.client_name AS 'ClientName',
	Matter.DisplayName AS 'MatterDesc',
	dim_matter_header_current.date_opened_practice_management AS 'MatterOpenDate',
	dim_fed_hierarchy_history.hierarchylevel4hist AS 'MatterOwnerTeam',
	dim_fed_hierarchy_history.display_name AS 'MatterOwner',
	InvPayor.InvNumber,
	InvMaster.InvDate,
	InvPayor.BalAmt AS 'DebtValue',
	InvPayor.BalFee AS 'OutstandingCosts',
	DATEDIFF(DAY, InvMaster.InvDate, GETDATE()) AS 'DaysOutstanding',
	CASE
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 0 AND 30 THEN '0 - 30 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 31 AND 60 THEN '31 - 60 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 61 AND 90 THEN '61 - 90 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 91 AND 180 THEN '91 - 180 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 181 AND 270 THEN '181 - 270 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 271 AND 360 THEN '271 - 360 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	BETWEEN 361 AND 720 THEN '361 - 720 Days'
		WHEN DATEDIFF(DAY, InvMaster.InvDate, GETDATE())	> 720 THEN 'Greater than 720 Days'
	END AS 'Days Banding',
	Address.FormattedString AS 'PayorFormattedString',
	dim_detail_core_details.zurich_branch AS 'Zurich Branch',
	dim_detail_core_details.clients_claims_handler_surname_forename AS 'Clients Claims Handler',
	COALESCE(dim_client_involvement.insurerclient_reference, red_dw.dbo.dim_client_involvement.client_reference)  'Insurer Client Reference',
	InvPayor.RefNumber		AS [Claim Reference on Invoice],
	dim_detail_core_details.brief_description_of_injury AS 'Injury Type',
	dim_detail_core_details.zurich_referral_reason AS 'Zurich Referral Reason',
	invoice_status_code,
	invoice_status_desc,
	CASE WHEN ISNUMERIC(dim_matter_header_current.master_client_code) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR, dim_matter_header_current.master_client_code), 8) 
							 ELSE CAST(RTRIM(dim_matter_header_current.master_client_code) AS VARCHAR(8)) END  AS master_client_code
	-- LD 20170928

	, InvPayor.BalBOA AS [Balance BOA]
	, InvPayor.BalHCo AS [Balance Hard Costs]
	, InvPayor.BalSCo AS [Balance Soft Costs]
	, InvPayor.BalInt AS [Balance Interest]
	, InvPayor.BalOth AS [Balance Other]
	, InvPayor.BalTax AS [Balance VAT]
	, InvPayor.OrgAmt
	, InvPayor.OrgFee
	, InvPayor.OrgHCost
	, InvPayor.OrgScost
	, InvPayor.OrgTax
	, dim_fed_hierarchy_history.worksforname AS [Team Manager] /*1.1*/
	, hsd.name AS HSD /*1.1*/
	, CASE	
		WHEN #outsource_mmi_claim_refs.mmi_claim_number IS NOT NULL THEN
			'Yes'
		ELSE
			NULL
	  END						AS [MMI Outsource Claim Reference],
	
	-- show total unpaid fees, disbs and VAT on each invoice? 
dim_bill_debt_narrative.udf_modified_by created_by,
dim_bill_debt_narrative.udf_narrative narrative
FROM  TE_3E_Prod.dbo.InvPayor  
INNER JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
INNER JOIN TE_3E_Prod.dbo.Client ON Client.ClientIndex = Matter.Client
INNER JOIN TE_3E_Prod.dbo.Payor ON Payor.PayorIndex = InvPayor.Payor
LEFT OUTER JOIN TE_3E_Prod.dbo.[Site] ON [Site].SiteIndex = CASE WHEN Payor.StmtSite IS NULL THEN Payor.[Site] ELSE Payor.StmtSite END
LEFT OUTER JOIN TE_3E_Prod.dbo.[Address] ON [Address].AddrIndex = [Site].[Address]

LEFT JOIN red_dw.dbo.dim_matter_header_current ON master_client_code + '-' + master_matter_number = Matter.Number COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code COLLATE DATABASE_DEFAULT
											   AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
											   AND dim_fed_hierarchy_history.activeud = 1
LEFT JOIN (SELECT DISTINCT name, employeeid, hierarchylevel3hist  FROM red_dw.dbo.dim_fed_hierarchy_history WHERE management_role_one = 'HoSD' AND dss_current_flag='Y' ) AS hsd ON hsd.hierarchylevel3hist = dim_fed_hierarchy_history.hierarchylevel3hist /*1.1*/
LEFT JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.client_code = ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber) COLLATE DATABASE_DEFAULT
										AND fact_dimension_main.matter_number = ISNULL(RIGHT(Matter.loadnumber, LEN(Matter.loadnumber) - CHARINDEX('-',Matter.loadnumber))
																						,
																						RIGHT(Matter.altnumber, LEN(Matter.altnumber) - CHARINDEX('-',Matter.altnumber))
																						)  COLLATE DATABASE_DEFAULT

LEFT JOIN red_dw.dbo.dim_client					ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_dw.dbo.dim_detail_core_details	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_client_involvement		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_bill_debt_narrative	ON InvPayor.InvNumber COLLATE DATABASE_DEFAULT = dim_bill_debt_narrative.bill_number
LEFT JOIN red_dw.dbo.dim_client AS master_client ON CASE WHEN ISNUMERIC(dim_matter_header_current.master_client_code) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR,dim_matter_header_current.master_client_code), 8) 
															ELSE CAST(RTRIM(dim_matter_header_current.master_client_code)  AS VARCHAR(8)) END
                         = master_client.client_code
LEFT OUTER JOIN #outsource_mmi_claim_refs
	ON #outsource_mmi_claim_refs.mmi_claim_number = LTRIM(RTRIM(COALESCE(dim_client_involvement.insurerclient_reference, red_dw.dbo.dim_client_involvement.client_reference)))
WHERE 
InvPayor.BalAmt <> 0
--and InvPayor.InvNumber = '02037226'
AND InvMaster.IsReversed <> 1


ORDER BY ISNULL(LEFT(Matter.loadnumber,(CHARINDEX('-',Matter.loadnumber)-1)),Client.altnumber), 
Address.FormattedString
END
GO
