SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [nhs].[NHSRLiveDelegatedAuthorityMatters]

AS

SELECT 

[MatterSphere Ref] = dim_matter_header_current.master_client_code +'-'+dim_matter_header_current.master_matter_number,
[Matter Description] = dim_matter_header_current.matter_description,
[Case Manager] = dim_fed_hierarchy_history.name,
[Key Personnel] = dim_matter_header_current.matter_partner_full_name,
[Instruction Type] = dim_detail_health.[nhs_instruction_type],
[Referral Reason] = dim_detail_core_details.[referral_reason],
[Present Position] = dim_detail_core_details.[present_position],
[Date Opened] = dim_matter_header_current.date_opened_case_management,
[Initial Report Required?] = dim_detail_core_details.[do_clients_require_an_initial_report],
[Date Initial Report Sent] = dim_detail_core_details.[date_initial_report_sent],
[Date of Last SLA Report] =  dim_detail_core_details.[date_subsequent_sla_report_sent] ,
[Date of Last Time Posting] = fact_matter_summary_current.[last_time_transaction_date]

  --key dates
       ,[NHSLA solicitor's report due]
	   ,[NHSLA expert report]
	   ,[Letter of response due]
       ,[Acknowledgement of Service]
       ,[Defence Due]
       ,[Directions Questionnaire]
       ,[CMC]
       ,[Disclosure]
       ,[Exchange of witness statements]
       ,[Exchange of medical reports]
       ,[Pre-trial checklist]
       ,[Trial date]



FROM red_dw.dbo.dim_matter_header_current

JOIN red_dw.dbo.fact_dimension_main
	ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key

JOIN red_dw.dbo.dim_detail_health
	ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key

JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

JOIN red_dw.dbo.dim_fed_hierarchy_history
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

LEFT JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key


	--Key Dates
	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Acknowledgement of Service] 
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE' AND tskDesc ='Acknowledgement of Service due - today'
	GROUP BY fileID) AS [KD_Acknowledgement] ON [KD_Acknowledgement].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Defence Due] FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc='Defences due - today'GROUP BY fileID) AS [KD_Defence] ON [KD_Defence].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Directions Questionnaire]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='AQ/Directions Questionnaire - today'
	GROUP BY fileID) AS [KD_DirectionsQuest] ON [KD_DirectionsQuest].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [CMC]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='CMC due - today'
	GROUP BY fileID) AS [KD_CMC] ON [KD_CMC].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Disclosure]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Disclosure - today'
	GROUP BY fileID) AS [KD_Disclosure] ON [KD_Disclosure].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Exchange of witness statements]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Exchange of witness statements - today'
	GROUP BY fileID) AS [KD_Witness] ON [KD_Witness].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Exchange of medical reports]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Exchange of medical reports Due - today'
	GROUP BY fileID) AS [KD_Medical] ON [KD_Medical].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Pre-trial checklist]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Pre-trial checklist due - today'
	GROUP BY fileID) AS [KD_PreTrial] ON [KD_PreTrial].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Trial date]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Trial date - today'
	GROUP BY fileID) AS [KD_TrialDate] ON [KD_TrialDate].fileID=ms_fileid 

 
	LEFT JOIN (SELECT fileID,MAX(tskDue) AS [NHSLA solicitor's report due]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc LIKE 'NHSLA solicitor''s report due%'  -- 'NHSLA solicitor''s report due'
	GROUP BY fileID) AS [KD_NHSLAsolicitorsreportdue] ON [KD_NHSLAsolicitorsreportdue].fileID=ms_fileid 

	LEFT JOIN (SELECT fileID,MAX(tskDue) AS [NHSLA expert report]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc LIKE 'NHSLA expert report%'
	GROUP BY fileID) AS [KD_NHSLAexpertreport] ON [KD_NHSLAexpertreport].fileID=ms_fileid 

	LEFT JOIN (SELECT fileID,MAX(tskDue) AS [Letter of response due]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc LIKE 'Letter of response due%'
	GROUP BY fileID) AS [KD_Letterofresponsedue] ON [KD_Letterofresponsedue].fileID=ms_fileid 

--Letter of response due


/*Filters*/

WHERE 1 = 1 
AND dim_matter_header_current.master_client_code ='N1001'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND LOWER(dim_detail_core_details.[delegated]) = 'yes'
AND dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] is null
AND dim_detail_outcome.[date_claim_concluded] is null
AND dim_detail_core_details.[present_position] = 'Claim and costs outstanding'

----/*Reporting Exclusions*/
AND dim_matter_header_current.reporting_exclusions=0
AND ISNULL(outcome_of_case, '') <> 'Exclude from reports'
GO
