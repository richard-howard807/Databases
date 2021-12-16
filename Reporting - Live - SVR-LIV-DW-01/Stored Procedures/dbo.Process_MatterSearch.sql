SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Process_MatterSearch]

@ClientGroup AS VARCHAR(400),
@ClientCode AS VARCHAR(400)   ,
@OpenDateFrom AS DATE,
@OpenDateTo AS DATE ,
@CloseDateFrom AS DATE, 
@CloseDateTo AS DATE , 
@FEDCode AS VARCHAR(30), 
@Partner AS VARCHAR(30) ,
@Matter AS VARCHAR(20)

AS

--/*Testing*/
--DECLARE 
--@ClientGroup AS VARCHAR(400) = 'All', 
--@ClientCode AS VARCHAR(400) = NULL  ,
--@OpenDateFrom AS DATE = NULL,
--@OpenDateTo AS DATE = NULL,
--@CloseDateFrom AS DATE = NULL, 
--@CloseDateTo AS DATE = NULL, 
--@FEDCode AS VARCHAR(30) = NULL, 
--@Partner AS VARCHAR(30) = NULL,
--@WorkType AS VARCHAR(MAX) = NULL,
--@Division AS VARCHAR(MAX) = 'Business Services',
--@Department AS VARCHAR(MAX) = NULL, 
--@Team AS VARCHAR(MAX) = NULL,
--@Matter AS VARCHAR(20) = NULL

--DROP TABLE IF EXISTS #Worktype
--DROP TABLE IF EXISTS #Division
--DROP TABLE IF EXISTS #Department
--DROP TABLE IF EXISTS #Team
--SELECT ListValue  INTO #Worktype FROM 	dbo.udt_TallySplit('|', @WorkType)
--SELECT ListValue  INTO #Division FROM 	dbo.udt_TallySplit('|', @Division)  
--SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit('|', @Department)  
--SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team) 

DROP TABLE IF EXISTS #Division
 CREATE TABLE #Division  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #Department
CREATE TABLE #Department  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #Team
CREATE TABLE #Team  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #Worktype
CREATE TABLE #Worktype  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

--INSERT INTO #Division
--SELECT ListValue
---- INTO #FedCodeList
--FROM dbo.udt_TallySplit('|', @Division)

--INSERT INTO #Department 
--SELECT ListValue 

--FROM dbo.udt_TallySplit('|', @Department)

--INSERT INTO #Team 
--SELECT ListValue 

--FROM dbo.udt_TallySplit('|', @Team)

--INSERT INTO #Worktype 
--SELECT  split_delimited_to_rows.val

--FROM  dbo.split_delimited_to_rows(@WorkType,'|')


SELECT 
						
			dim_matter_header_current.[dim_matter_header_curr_key],
			dim_client.[client_code],
			dim_client.[client_name],
			dim_matter_header_current.[matter_number],
			dim_matter_header_current.[matter_description],
			dim_fed_hierarchy_history.name as [matter_owner_name],
			dim_matter_branch.[branch_code],
			dim_matter_header_current.[matter_partner_full_name],
			dim_fed_hierarchy_history.display_name AS [matter_owner_displayname],
			dim_fed_hierarchy_history.hierarchylevel4hist [matter_owner_team],
			dim_matter_worktype.[work_type_name] AS [work_type_name],
			dim_matter_header_current.date_opened_practice_management [matter_opened_practice_management_calendar_date],
			dim_matter_header_current.date_closed_practice_management [matter_closed_practice_management_calendar_date],
			lastbilldate.calendar_date AS [last_bill_calendar_date],
			last_time_transaction_date AS [last_time_calendar_date],
			fact_detail_elapsed_days.[elapsed_days],
			fact_finance_summary.[client_account_balance_of_matter],
			fact_finance_summary.[disbursement_balance],
			fact_finance_summary.[unpaid_bill_balance],
			fact_finance_summary.[wip],
			fact_finance_summary.[defence_costs_billed],
			[time_billed] = CAST(ISNULL(fact_finance_summary.[time_billed], 0) AS DECIMAL(18,2)),
			dim_matter_header_current.[master_client_code],
			dim_matter_header_current.[master_matter_number],
			dim_matter_group.[matter_group_name],
			dim_matter_header_current.[billing_arrangement],
			dim_matter_header_current.[billing_arrangement_description],
			dim_matter_header_current.[billing_rate],
            dim_fed_hierarchy_history.hierarchylevel2hist [matter_owner_business_line],
			dim_matter_header_current.[billing_rate_description],
			dim_client.[client_group_name], 
			Department = dim_fed_hierarchy_history.hierarchylevel3hist,
			[3E Weightmans Ref] = dim_matter_header_current.master_client_code + '-' + master_matter_number ,
			[Open/Closed] = CASE WHEN dim_matter_header_current.date_closed_practice_management IS NULL THEN 'Open' ELSE 'Closed' END
			,[Open BOA]
			,BilledBOA
			,ChargeableHours = ISNULL(ChargeableHours.ChargeableHours, 0)
			,WIPMins = ISNULL(ChargeableHours.WIPMins, 0) 

						FROM red_dw..fact_dimension_main
						JOIN red_dw..dim_matter_header_current
						ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
						JOIN red_dw..dim_client
						ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
						JOIN red_dw..dim_fed_hierarchy_history
						ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
						LEFT JOIN red_dw..dim_matter_branch
						ON dim_matter_branch.branch_code = dim_matter_header_current.branch_code
						LEFT JOIN red_dw..dim_matter_worktype
						ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
						LEFT JOIN red_dw..fact_detail_elapsed_days
						ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
						LEFT JOIN red_dw..fact_finance_summary
						ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
						LEFT JOIN red_dw..dim_matter_group
						ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
						LEFT JOIN red_dw..fact_matter_summary_current 
						ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
						LEFT JOIN red_dw.dbo.dim_date lastbilldate 
						ON lastbilldate.dim_date_key = fact_matter_summary_current.dim_date_key
						LEFT JOIN 

						(
						SELECT  dim_matter_header_curr_key, SUM(OrgBOA)  AS [Open BOA]
                        ,SUM(CASE WHEN OrgBOA>0 THEN OrgBOA ELSE 0 END) AS BilledBOA
                         FROM TE_3E_Prod.dbo.InvMaster
                        INNER JOIN MS_Prod.config.dbFile
                         ON LeadMatter=fileExtLinkID
                        INNER JOIN red_dw.dbo.dim_matter_header_current
                         ON fileID=ms_fileid
                        
                        GROUP BY dim_matter_header_curr_key
                        HAVING SUM(OrgBOA)<>0
						) BOA ON BOA.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


						LEFT JOIN 

						(
						SELECT 

                        TRIM(a.client_code) client_code,
                        TRIM(a.matter_number) matter_number,
                        ChargeableHours = SUM(a.minutes_recorded) /60 ,
                        [WIPMins] = SUM(CASE WHEN t.transaction_type = 'Unbilled' THEN a.minutes_recorded END/60) 
                        
                        FROM
                        red_dw.dbo.fact_all_time_activity a
                         left join
                          red_dw.dbo.dim_all_time_activity t
                           on a.dim_all_time_activity_key = t.dim_all_time_activity_key
                          left join red_dw.dbo.dim_date d3
                          on d3.dim_date_key = a.dim_transaction_date_key
                         
                         where isactive = 1
                         
                         AND ISNULL(t.time_activity_code, '') NOT IN ('Bill','Abmt','W/O')
                         
                         --AND TRIM(a.client_code) = 'W22559'
                         --AND a.matter_number = '00000027'
                         --AND t.transaction_type <> 'Written Off Transaction'
                         
                         GROUP BY 
                         
                         a.client_code,
                         a.matter_number

						) ChargeableHours ON ChargeableHours.client_code = TRIM(dim_client.client_code) AND ChargeableHours.matter_number = TRIM(dim_matter_header_current.matter_number)


					 -- INNER JOIN #Division ON #Division.ListValue = dim_fed_hierarchy_history.hierarchylevel2
                      -- INNER JOIN #Department ON #Department.ListValue = dim_fed_hierarchy_history.hierarchylevel3
                      -- INNER JOIN #Team ON #Team.ListValue = dim_fed_hierarchy_history.hierarchylevel4
                     --   INNER JOIN #Worktype ON #Worktype.ListValue = dim_matter_worktype.[work_type_name]

						WHERE 1=1
					AND dim_matter_header_current.[reporting_exclusions]<>1
					AND dim_client.[client_code] <> '00030645'
					AND CASE WHEN @ClientGroup ='All' THEN ISNULL(dim_client.[client_group_name], '') ELSE @ClientGroup END = ISNULL(dim_client.[client_group_name],'') --dim_client[client_group_name] = if(@ClientGroup = blank(), dim_client[client_group_name], @ClientGroup),
					AND CASE WHEN ISNULL(@ClientCode, '') = '' THEN TRIM(dim_client.[client_code]) ELSE TRIM(@ClientCode) END = TRIM(dim_client.[client_code]) -- dim_client[client_code] = if(@ClientCode = blank(), dim_client[client_code], @ClientCode),
					AND CASE WHEN  ISNULL(@FEDCode, '') = ''  THEN fed_code ELSE @FEDCode END = fed_code --dim_fed_hierarchy_history_matter_owner[matter_owner_fed_code] = if(@FEDCode = blank(), dim_fed_hierarchy_history_matter_owner[matter_owner_fed_code], @FEDCode),
					AND CASE WHEN  ISNULL(@Partner, '') = ''  THEN matter_partner_code ELSE @Partner END = matter_partner_code --dim_matter_header_current[matter_partner_code] = if(@Partner = blank(), dim_matter_header_current[matter_partner_code], @Partner),
					AND CASE WHEN ISNULL(@Matter, '') = ''  THEN dim_matter_header_current.matter_number ELSE @Matter END = dim_matter_header_current.matter_number --dim_matter_header_current[matter_number] = if(@Matter = blank(), dim_matter_header_current[matter_number], @Matter)
					AND dim_matter_header_current.date_opened_practice_management
					BETWEEN ISNULL(@OpenDateFrom, '1990-01-01') AND ISNULL(@OpenDateTo, '3000-01-01') -- 	dim_date_matter_opened_practice_management[dim_date_key] >= if(value(@OpenDateFrom) = blank(), 19900101, value(@OpenDateFrom)), dim_date_matter_opened_practice_management[dim_date_key] <= if(value(@OpenDateTo) = blank(), 30000101, value(@OpenDateTo)),
					AND  ISNULL(dim_matter_header_current.date_closed_practice_management, '1990-01-01')
					BETWEEN ISNULL(@CloseDateFrom, '1990-01-01') AND ISNULL(@CloseDateTo, '3000-01-01') --	dim_date_matter_closed_practice_management[dim_date_key] >= if(value(@CloseDateFrom) = blank(), -1, value(@CloseDateFrom)), dim_date_matter_closed_practice_management[dim_date_key] <= if(value(@CloseDateTo) = blank(), 30000101, value(@CloseDateTo)),

				--AND dim_matter_header_current.master_client_code +'-' +master_matter_number
				--= '0016344J-2'
				    
					
				 -- AND TRIM(dim_matter_worktype.[work_type_name]) IN (TRIM(@Worktype)) -- (TRIM(@Worktype)) --pathcontains(@WorkType, dim_matter_worktype[work_type_name]),
					
				--AND TRIM(dim_fed_hierarchy_history.hierarchylevel2hist) IN (@Division)--PATHCONTAINS(@Division,dim_fed_hierarchy_history_matter_owner[matter_owner_business_line]),

				--AND TRIM(dim_fed_hierarchy_history.hierarchylevel3hist) IN (@Department) --pathcontains(@Department,dim_fed_hierarchy_history_matter_owner[matter_owner_practice_area]),

				--AND	TRIM(dim_fed_hierarchy_history.hierarchylevel4hist) IN (@Team)	--PATHCONTAINS(@Team,dim_fed_hierarchy_history_matter_owner[matter_owner_team]),
				
				    
		

order by 
dim_client.[client_code],
dim_matter_header_current.[matter_number]

--=iif(
--isnothing(
--lookup(
--Fields!dim_matter_header_curr_key.Value,
--Fields!Matter_MatterID_.Value,
--Fields!ID_ChargeableHours_.Value, "ChargeableHours")
--),
--0,
--lookup(
--Fields!dim_matter_header_curr_key.Value,
--Fields!Matter_MatterID_.Value,
--Fields!ID_ChargeableHours_.Value, "ChargeableHours")
--)

--=iif(
--isnothing(
--lookup(
--Fields!dim_matter_header_curr_key.Value,
--Fields!Matter_MatterID_.Value,
--Fields!ID_WIPMins_.Value, "ChargeableHours")
--),
--0,
--lookup(
--Fields!dim_matter_header_curr_key.Value,
--Fields!Matter_MatterID_.Value,
--Fields!ID_WIPMins_.Value, "ChargeableHours")
--)
GO
