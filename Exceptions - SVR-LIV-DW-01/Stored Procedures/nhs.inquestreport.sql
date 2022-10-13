SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [nhs].[inquestreport]--EXEC [nhs].[NHSRRawDataReport] '1009','Dispute on liability and quantum',NULL,NULL
(
@Team AS NVARCHAR(MAX)
,@Status AS NVARCHAR(MAX)
,@Worktype AS NVARCHAR(MAX)
,@StartDate AS DATE NULL
,@EndDate AS DATE NULL
)
AS
BEGIN

SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT ListValue  INTO #Status  FROM Reporting.dbo.[udt_TallySplit]('|', @Status)
SELECT ListValue INTO #Worktype FROM Reporting.dbo.[udt_TallySplit]('|', @Worktype)



SELECT

	 dim_matter_header_current.master_client_code [Client],
       dim_matter_header_current.master_matter_number [Matter],
       dim_matter_header_current.client_name [Client Name],
       name [Case Manager],
       hierarchylevel4hist [Team],
       dim_matter_worktype.work_type_name [Work Type],
       matter_description [Description],
       date_instructions_received [Date Instructions Recieved],
       reg_cause_code [Cause Code],
       dim_detail_rsu.reg_case_manager_at_trust [Case Manager at Trust],
       dim_detail_rsu.reg_pre_inquest_review_hearing_date [Pre-Inquest review hearing date ],
       dim_detail_rsu.reg_date_of_inquest [Date of Inquest],
       coroners_court [Coroner's Court],
       reg_name_of_coroner [Name of Coroner],
       reg_is_this_an_article_two_inquest [Is this an Article 2 Inquest?                       ],
       reg_is_this_an_inquest_with_a_jury [Is this an Inquest with a Jury?              ],
       reg_will_we_instruct_counsel [Will we instruct counsel?      ],
       witness_statements_required [Are witness statements required              ],
       reg_are_any_experts_involved [Are any experts involved?     ],
       reg_complaint_or_claim_by_family_intimated [Complaint or claim by family intimated           ],
       reg_si_rca_undertaken [SI/RCA undertaken           ],
       reg_if_there_is_a_claim_by_family_has_nhsla_been_notified [If there is a claim by family, has NHSR been notified  ],
       is_there_a_prevention_of_future_deaths_report [Is there a Prevention of Future Deaths report? ],
       reg_press_involvement [Press involvement     ],
       reg_any_witnesses_referred_to_a_regulatory_body_ie_gmc [Any witnesses referred to a Regulatory body ie GMC?    ],
       reg_did_the_si_identify_the_issues_exposed_at_inquest [Did the SI identify the issues exposed at Inquest?   ],
       reg_verdict [Conclusion        ], 
CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END AS [Status ]


FROM red_dw.dbo.fact_dimension_main

INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

INNER JOIN #Status AS Status ON Status.ListValue   COLLATE DATABASE_DEFAULT = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT

INNER JOIN #Worktype AS Worktype ON Worktype.ListValue COLLATE DATABASE_DEFAULT = work_type_name COLLATE DATABASE_DEFAULT

 left JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    INNER JOIN red_Dw.dbo.dim_client
        ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
    LEFT JOIN red_Dw.dbo.dim_detail_critical_mi
        ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
    LEFT JOIN red_Dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_Dw.dbo.dim_matter_worktype
        ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
    LEFT OUTER JOIN red_dw.dbo. dim_detail_rsu
        ON dim_detail_rsu.dim_detail_rsu_key = fact_dimension_main.dim_detail_rsu_key
    LEFT JOIN red_Dw.dbo.dim_detail_health
        ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
    LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key



		
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

INNER JOIN #Status AS Status ON Status.ListValue   COLLATE DATABASE_DEFAULT = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT

INNER JOIN #Worktype AS Worktype ON Worktype.ListValue COLLATE DATABASE_DEFAULT = work_type_name COLLATE DATABASE_DEFAULT



WHERE work_type_name IN ( 'Inquest                                 ', 'Healthcare NHS Inquest                  ',
                          'Healthcare non-NHS Inquest              '
                        )


and ((red_dw.dbo.dim_matter_header_current.date_opened_case_management >= @startdate OR @startdate is null) and  red_dw.dbo.dim_matter_header_current.date_opened_case_management<=  @enddate  OR @enddate is null) 
AND reporting_exclusions = 0 ;


END 
GO
