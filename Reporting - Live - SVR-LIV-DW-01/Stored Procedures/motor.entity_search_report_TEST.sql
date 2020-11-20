SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





--=======================================================================
-- Author:	Lucy Dickinson
-- Date:	12/11/2018
-- Description:  Entity Search report
-- =======================================================================
-- Search Types
-- 1 = 'Entity Name' 
-- 2 = 'Address'
-- 3 = 'Post Code'
-- 4 = 'Vehicle Registration Number'
-- 5 = 'National Insurance Number'
-- 6 = 'GMC Number'
-- 7 = 'Claimants DOB' 
--10 = 'Insurer Client Reference'
--11 = 'Claimants Solicitors'
--12 = 'Claimants Solicitors reference'
--13 = 'Defendant'
--14 = 'Defendant reference'
--
-- I have used the ConflictSearch database as it houses both MS and FED involvements
-- and used temp tables to speed up the final queries as they were taking minutes to run
-- and this took the time down to 37secs which is still not great.  Need to try and improve this but time is short
-- and this is good enough
--================================================


/*

Select 1 SearchType, 'Entity Name' SearchTypeDescription
Union all
Select 2, 'Address'
union all
Select 3, 'Post Code'
union all
Select 4, 'Vehicle Reg Number (no spaces)'
union all
Select 5, 'National Insurance Number'
union all
Select 6, 'GMC Number'
Union all
Select 7,  'Claimants DOB (yyyymmdd)' 
Union all
Select 10, 'Insurer Client Reference'
Union all
Select 11, 'Claimant Solicitor'
Union all
Select 12, 'Claimant Solicitor Reference'
Union all
Select 13, 'Defendant'
Union all
Select 14, 'Defendant Reference'

ORDER by 1

*/


CREATE PROCEDURE [motor].[entity_search_report_TEST]
(
		@SearchType SMALLINT					
		,@SearchDetail1 AS VARCHAR(1000)
	
)
AS

-- For testing purposes only

	--Declare @SearchType smallint
	--Declare @SearchDetail1 varchar(300)
	----Declare @SearchDetail2 varchar(300)
	--Set @SearchType = 3
	--Set @SearchDetail1 = 'WF1 3PU'
	----Set @SearchDetail2 = NULL




	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- changing to upper case here to avoid having to do this in the join
	SET @SearchDetail1= Upper(@SearchDetail1)
	--SET @SearchDetail2= Upper(@SearchDetail2)

	

	
	Declare @ClientMatter Table (
		Client varchar(8)
		,Matter varchar(8))

	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#entity_search_results')) 
			DROP TABLE #entity_search_results

	Create table #entity_search_results (

			  [Client] varchar (100)
			, [Matter] varchar (100)
			, [MS Ref] varchar (100)
			, [Entity Name] varchar(4000)
			, [Fee Earner] varchar (300)
			, [Team] varchar (100)
			, [Present Position] VARCHAR(255) -- Added 19/11/2020
			, [Status] varchar(200)
			, [Date Closed] date
			, [Address] varchar(1000)
			, [InvolvementType] varchar(200)
			, [IsLinkedFile] varchar(100)  
			, [IsLeadFile]   varchar(100)
			, [LeadMatterNumber] varchar(500)
			, [Suspicion of Fraud] varchar(100)
			, [Initial Fraud Type] varchar(100)
			, [Current Fraud Type] varchar(100)
			, [Credit Hire] varchar(500)
			, [Vehicle Reg Number 1] varchar(200)
			, [Vehicle Reg Number 2] varchar(200)
			, [National Insurance Number] varchar(500)
			, [GMC Number] varchar(500)
			, [Date of Birth] DATE
          	, [Insurer Client Ref] varchar(5000)
			, [Claimant Solicitor] varchar(5000)
			, [Claimant Solicitor Ref] varchar(5000)
			, [Defendant] VARCHAR (5000) 
			, [Defendant Ref] VARCHAR (5000)
			, [Claimant Medical Expert] VARCHAR(5000)
			, [TP Accident Management Company] VARCHAR(5000)
			, [TP Hire Company] VARCHAR(5000)
			, [TP Storeage Recovery Company] VARCHAR(5000)
			, [Claimant Name] VARCHAR(5000)
			 ,[SourceSystem] VARCHAR(300)
		)


	--select * from #entity_search_results



	IF @SearchType = 1 -- Name
	BEGIN

		IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#name_list')) 
				DROP TABLE #name_list

			SELECT DISTINCT 	MatterDetails.client_code AS Client
			, MatterDetails.matter_number AS Matter
			, dd.Description [matter_description]
			, dd.Capacity [InvolvementType]
			, LTRIM(RTRIM(tb1.Text)) [EntityName]
			, dd.Type [SourceSystem]
			, RTRIM(tb2.Text)  [Address]
			--,tb1.*
  
			INTO #name_list
			FROM
				ConflictSearch.dbo.ConflictSearch tb1
			LEFT OUTER JOIN ConflictSearch.dbo.ConflictSearch tb2
			ON  tb1.Reference = tb2.Reference
				AND tb1.SourceID= tb2.SourceID -- Added as we are now pulling data from MS and FED.
				AND tb2.TYPE = 'Address'
				AND tb1.DESCRIPTION IN ('Individual Client','Organisational Client','Individual Involvement','Organisational Involvement')
				AND tb1.TYPE = 'Entity'
		   INNER JOIN ConflictSearch.dbo.ConflictSearchDrilldownDetailsTable dd
			ON  tb1.EntityCode = dd.code
				AND tb1.SourceID= dd.SourceID -- Added as we are now pulling data from MS and FED.
				AND dd.Client NOT IN (SELECT ClientId
										FROM [ConflictSearch].[dbo].[ClientExclusionList] )
				AND dd.Matter NOT IN ('0','ML') -- exclude matter zero and ML
			LEFT OUTER JOIN (SELECT  ms_fileid,case_id,client_code,matter_number
			FROM red_dw.dbo.dim_matter_header_current
			) AS MatterDetails
			 ON (CASE WHEN dd.SourceID=1 THEN MatterDetails.case_id ELSE MatterDetails.ms_fileid END)=dd.CaseID
			WHERE
				--CONTAINS ( tb1.Text, @SearchDetail1 )
				tb1.Text LIKE '%' + @SearchDetail1 + '%'  
				AND tb1.TYPE IN ('Entity','Matter')
            
				AND ( tb1.[EntityCode] NOT IN ( SELECT ClientId
  FROM [ConflictSearch].[dbo].[ClientExclusionList]  ) )
			AND tb1.DESCRIPTION IN ('Individual Client','Organisational Client',
															 'Individual Involvement',
															 'Organisational Involvement')
	END


	IF @SearchType = 2 -- Address
	BEGIN
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#entity_address_list')) 
				DROP TABLE #entity_address_list
		

		--SELECT DISTINCT 	dd.Client
		--	, dd.Matter
		--	, dd.Description [matter_description]
		--	, dd.Capacity [InvolvementType]
		--	, tb1.Text [EntityName]
		--	, dd.Type [SourceSystem]
		--	, tb2.Text  [Address]
			
		--INTO #entity_address_list
		--FROM ConflictSearch.dbo.ConflictSearch tb1
		--LEFT OUTER JOIN ConflictSearch.dbo.ConflictSearch tb2
		--	ON  tb1.Reference = tb2.Reference
		--	AND tb1.SourceID= tb2.SourceID -- Added as we are now pulling data from MS and FED.
		--	AND tb2.TYPE = 'Address'
		--	AND tb1.DESCRIPTION IN ('Individual Client','Organisational Client','Individual Involvement','Organisational Involvement')
		--	AND tb1.TYPE = 'Entity'
		--Left JOIN ConflictSearch.dbo.ConflictSearchDrilldownDetailsTable dd
		--	ON  tb1.EntityCode = dd.code
		--AND tb1.SourceID= dd.SourceID -- Added as we are now pulling data from MS and FED.
  --      AND dd.Client NOT IN ( '00121614', '00076202',
  --                              '00047237', '00006930',
  --                              '00123739', '00030645' )
		--AND dd.Matter NOT IN ('0','ML') -- exclude matter zero and ML
		--WHERE
  --      (		 ( tb2.Address1 LIKE '%' + @SearchDetail1 + '%' )
		--		OR ( tb2.Address2 LIKE '%' + @SearchDetail1 + '%' )
  --              OR ( tb2.Address3 LIKE '%' + @SearchDetail1 + '%' )
  --              OR ( tb2.Address4 LIKE '%' + @SearchDetail1 + '%' )
            
                           
  --          )
  --      AND tb1.TYPE IN ('Entity','Matter')
            
  --      AND tb1.[EntityCode] NOT IN ( '00121614', '00076202',
  --                                      '00047237', '00006930',
  --                                      '00123739', '00030645' ) 
		--AND tb1.DESCRIPTION IN ('Individual Client','Organisational Client')

		
		SELECT Distinct
					 MatterDetails.client_code AS  Client
					, MatterDetails.matter_number AS  Matter
					, dd.Description [matter_description]
					, dd.Capacity [InvolvementType]
					, b.CleanName [EntityName]
					, dd.Type [SourceSystem]
					, a.CleanName  [Address]
					, CaseID -- (contains caseids (FED) and fileids (MS)
					
		INTO #entity_address_list
		FROM ConflictSearch.dbo.ConflictSearch a	 
		left join ConflictSearch.dbo.ConflictSearch b 
		ON  a.Reference = b.Reference
					AND a.SourceID= b.SourceID
					and b.Type <> 'Address'

		INNER JOIN ConflictSearch.dbo.ConflictSearchDrilldownDetailsTable dd
					ON  a.EntityCode = dd.code
					and a.SourceID = dd.SourceID
					LEFT OUTER JOIN (SELECT  ms_fileid,case_id,client_code,matter_number
			FROM red_dw.dbo.dim_matter_header_current
			) AS MatterDetails
			 ON (CASE WHEN dd.SourceID=1 THEN MatterDetails.case_id ELSE MatterDetails.ms_fileid END)=dd.CaseID

WHERE a.CleanName LIKE '%' + @SearchDetail1 + '%' 
		and a.Type = 'Address'
		and dd.Matter NOT IN ('0','ML')
		AND dd.Client NOT IN ( SELECT ClientId
  FROM [ConflictSearch].[dbo].[ClientExclusionList]  )
	END


	IF @SearchType = 3 -- Postcode
	BEGIN
		
	PRINT CONVERT(VARCHAR(30),GETDATE(),120)

		--SET @SearchDetail1 = REPLACE(@SearchDetail1,' ','')
		
		IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#entity_postcode_list')) 
				DROP TABLE #entity_postcode_list

		SELECT Distinct
					 MatterDetails.client_code AS Client
					, MatterDetails.matter_number AS Matter
					, dd.Description [matter_description]
					, dd.Capacity [InvolvementType]
					, b.CleanName [EntityName]
					, dd.Type [SourceSystem]
					, a.CleanName  [Address]
					, CaseID -- (contains caseids (FED) and fileids (MS)
					
		INTO #entity_postcode_list
		FROM ConflictSearch.dbo.ConflictSearch a	 
		left join ConflictSearch.dbo.ConflictSearch b 
		ON  a.Reference = b.Reference
					AND a.SourceID= b.SourceID
					and b.Type <> 'Address'

		INNER JOIN ConflictSearch.dbo.ConflictSearchDrilldownDetailsTable dd
					ON  a.EntityCode = dd.code
					and a.SourceID = dd.SourceID
					LEFT OUTER JOIN (SELECT  ms_fileid,case_id,client_code,matter_number
			FROM red_dw.dbo.dim_matter_header_current
			) AS MatterDetails
			 ON (CASE WHEN dd.SourceID=1 THEN MatterDetails.case_id ELSE MatterDetails.ms_fileid END)=dd.CaseID

WHERE a.CleanName LIKE '%' + @SearchDetail1 + '%' 
		and a.Type = 'Address'
		and dd.Matter NOT IN ('0','ML')
		AND dd.Client NOT IN ( SELECT ClientId
  FROM [ConflictSearch].[dbo].[ClientExclusionList] )
	
	END
	
	IF @SearchType = 4 -- Vehicle Registration Number
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','') -- gets rid of spaces
		INSERT INTO @ClientMatter
		SELECT main.client_code client, main.matter_number matter
		FROM red_dw.dbo.fact_dimension_main main
		INNER JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key 
		WHERE UPPER(REPLACE(COALESCE(fraud.fraud_vehicle_1_registration_number,fraud.fraud_vehicle_2_registration_number,''),' ','')) LIKE  '%' +@SearchDetail1+'%'  -- Change to upper case and remove spaces
		AND main.client_code NOT IN ('00121614'
,'00076202'
,'00047237'
,'00006930'
,'00123739'
,'00030645'
,'95000C'
,'00453737')
	END
	
	IF @SearchType = 5 -- National Insurance Number
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','') -- gets rid of spaces
		INSERT INTO @ClientMatter
		SELECT main.client_code client, main.matter_number matter
		FROM red_dw.dbo.fact_dimension_main main
		INNER JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key  AND fraud.fraud_ll_claimants_national_insurance_number IS NOT NULL 
		WHERE UPPER(REPLACE(fraud.[fraud_ll_claimants_national_insurance_number],' ','')) LIKE  '%' +@SearchDetail1+'%' -- contents to uppercase and removes spaces
		AND main.client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END

	IF @SearchType = 6 -- GMC Number
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','') -- remove spances
		INSERT INTO @ClientMatter
		SELECT main.client_code client, main.matter_number matter
		FROM red_dw.dbo.fact_dimension_main main
		INNER JOIN red_dw.dbo.dim_detail_litigation lit ON lit.dim_detail_litigation_key = main.dim_detail_litigation_key AND lit.gmc_number IS NOT NULL 
		WHERE UPPER(REPLACE(lit.gmc_number,' ','')) LIKE  '%' +@SearchDetail1+'%' 
		AND main.client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END

	IF @SearchType = 7 -- Claimants DOB
	BEGIN
			
		INSERT INTO @ClientMatter
		SELECT main.client_code client, main.matter_number matter
		FROM red_dw.dbo.fact_dimension_main main
		INNER JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key AND core.claimants_date_of_birth IS NOT NULL 
	    WHERE core.[claimants_date_of_birth]  =  @SearchDetail1
		AND main.client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	
	END

	IF @SearchType = 10 -- Insurer Client Reference -- red_dw.dbo.dim_client_involvement
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','')
		INSERT INTO @ClientMatter
		SELECT client_code client, matter_number matter
		FROM red_dw.dbo.dim_client_involvement (NOLOCK)
	    WHERE insurerclient_reference IS NOT NULL 
		AND UPPER(REPLACE(insurerclient_reference,' ','')) LIKE  '%' +@SearchDetail1+'%' 
		AND client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	
	END

	IF @SearchType = 11 -- Claimants Solicitors -- red_dw.dbo.dim_claimant_thirdparty_involvement
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','')
		INSERT INTO @ClientMatter
		SELECT client_code client, matter_number matter
		FROM red_dw.dbo.dim_claimant_thirdparty_involvement
		
	    WHERE claimantsols_name IS NOT NULL 
		AND UPPER(REPLACE(claimantsols_name,' ','')) LIKE  '%' +@SearchDetail1+'%' 
		AND client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END

		IF @SearchType = 12 -- Claimants Solicitors Reference -- red_dw.dbo.dim_claimant_thirdparty_involvement
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','')
		INSERT INTO @ClientMatter
		SELECT client_code client, matter_number matter
		FROM red_dw.dbo.dim_claimant_thirdparty_involvement
	    WHERE claimantsols_reference IS NOT NULL 
		AND UPPER(REPLACE(claimantsols_reference,' ','')) LIKE  '%' +@SearchDetail1+'%' 
	  	AND client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END

	IF @SearchType = 13 -- Defendant --  red_dw.dbo.dim_defendant_involvement
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','')
		INSERT INTO @ClientMatter
		SELECT client_code client, matter_number matter
		FROM red_dw.dbo.dim_defendant_involvement (NOLOCK)
		WHERE defendant_name IS NOT NULL 
	    AND UPPER(REPLACE(defendant_name,' ','')) LIKE  '%' +@SearchDetail1+'%' 
		AND client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END

	IF @SearchType = 14 -- Defendant Reference -- red_dw.dbo.dim_defendant_involvement
	Begin
		
		SET @SearchDetail1 = REPLACE(@SearchDetail1, ' ','')
		INSERT INTO @ClientMatter
		SELECT client_code client, matter_number matter
		FROM  red_dw.dbo.dim_defendant_involvement (NOLOCK)
		WHERE defendant_reference IS NOT NULL 
	    AND UPPER(REPLACE(defendant_reference,' ','')) LIKE  '%' +@SearchDetail1+'%' 
		AND client_code NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END


	IF @SearchType = 1
	BEGIN

		INSERT INTO #entity_search_results
		SELECT		
			main.client_code					AS	[Client]
			, main.matter_number				AS	[Matter]
			, header.master_client_code +'-'+master_matter_number	AS  [MS Ref]
			, EntityName				  		AS	[Entity Name]
			, header.matter_owner_full_name		AS	[Fee Earner]
			, fed.hierarchylevel4hist			AS	[Team]
			, core.[present_position]           AS  [Present Position] --Added 19/11/2020 - MT
			, claim.[status]					AS	[Status]
			, header.date_closed_case_management AS [Date Closed]
			, [Address]
			, [InvolvementType]
			--, [Address2]
			--, [Address3]
			--, [Address4]
			--, [PostCode]
			, RTRIM(ISNULL(core.is_this_a_linked_file,''))	[IsLinkedFile]  
			, RTRIM(ISNULL(core.[is_this_the_lead_file],''))   [IsLeadFile]   
			, RTRIM(ISNULL(core.[lead_file_matter_number_client_matter_number], ''))	[LeadMatterNumber]
			, core.suspicion_of_fraud [Suspicion of Fraud]
			, fraud.fraud_initial_fraud_type AS [Initial Fraud Type]
			, fraud.fraud_current_fraud_type AS [Current Fraud Type]
			, core.credit_hire AS [Credit Hire]
			, fraud.fraud_vehicle_1_registration_number AS [Vehicle Reg Number 1]
			, fraud.fraud_vehicle_2_registration_number AS [Vehicle Reg Number 2]
			, fraud.fraud_ll_claimants_national_insurance_number AS [National Insurance Number]
			, lit.gmc_number AS [GMC Number]
			, core.claimants_date_of_birth [Date of Birth]
			, invol3.insurerclient_reference AS [Insurer Client Ref]
			, invol1.claimantsols_name AS [Claimant Solicitor]
			, invol1.claimantsols_reference AS [Claimant Solicitor Ref]
			, invol2.defendant_name AS [Defendant]
			, invol2.defendant_reference AS [Defendant Ref]
			, invol4.claimantmedexp_name [Claimant Medical Expert]
			, invol1.tpaccmancomp_name AS [TP Accident Management Company]
			, invol1.tphirecomp_name AS [TP Hire Company]
			, invol1.tpstorereccomp_name AS [TP Storeage Recovery Company]
			, invol1.claimant_name AS [Claimant Name]
			, [SourceSystem]
			
		
	    
		FROM #name_list AS AllData
		INNER JOIN red_dw.dbo.fact_dimension_main main ON  AllData.Client = main.client_code COLLATE DATABASE_DEFAULT AND AllData.Matter = main.matter_number COLLATE DATABASE_DEFAULT --- need to join to client code and matter number here after I've got the entity address
		INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key
		LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
		LEFT JOIN red_dw.dbo.dim_detail_litigation lit ON lit.dim_detail_litigation_key = main.dim_detail_litigation_key
		LEFT JOIN red_dw.dbo.dim_detail_claim claim ON claim.dim_detail_claim_key = main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
		
		-- additional involvements
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement invol1 ON invol1.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement invol2 ON invol2.dim_defendant_involvem_key = main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.dim_client_involvement invol3 ON invol3.dim_client_involvement_key = main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_experts_involvement invol4  ON invol4.dim_experts_involvemen_key = main.dim_experts_involvemen_key
		WHERE main.client_code  NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')

 

	END
	IF @SearchType = 2
	BEGIN
		
		INSERT INTO #entity_search_results
		SELECT		
			main.client_code				AS			[Client]
			, main.matter_number			AS			[Matter]
			, header.master_client_code +'-'+master_matter_number	AS  [MS Ref]
			, EntityName				  	AS		[Entity Name]
			, header.matter_owner_full_name	AS		[Fee Earner]
			, fed.hierarchylevel4hist		AS		[Team]
			, core.[present_position]       AS      [Present Position] -- Added 19/11/2020 - MT
			, claim.[status]				AS		[Status]
			, header.date_closed_case_management AS		 [Date Closed]
			, [Address] 
			, [InvolvementType]
			, RTRIM(ISNULL(core.is_this_a_linked_file,'')) AS	[IsLinkedFile]  
			, RTRIM(ISNULL(core.[is_this_the_lead_file],''))  AS [IsLeadFile]   
			, RTRIM(ISNULL(core.[lead_file_matter_number_client_matter_number], '')) AS	[LeadMatterNumber]
			, core.suspicion_of_fraud [Suspicion of Fraud]
			, fraud.fraud_initial_fraud_type AS [Initial Fraud Type]
			, fraud.fraud_current_fraud_type AS [Current Fraud Type]
			, core.credit_hire AS [Credit Hire]
			, fraud.fraud_vehicle_1_registration_number AS [Vehicle Reg Number 1]
			, fraud.fraud_vehicle_2_registration_number AS [Vehicle Reg Number 2]
			, fraud.fraud_ll_claimants_national_insurance_number AS [National Insurance Number]
			, lit.gmc_number AS [GMC Number]
			, core.claimants_date_of_birth [Date of Birth]
			, invol3.insurerclient_reference AS [Insurer Client Ref]
			, invol1.claimantsols_name AS [Claimant Solicitor]
			, invol1.claimantsols_reference AS [Claimant Solicitor Ref]
			, invol2.defendant_name AS [Defendant]
			, invol2.defendant_reference AS [Defendant Ref]
			, invol4.claimantmedexp_name [Claimant Medical Expert]
			, invol1.tpaccmancomp_name AS [TP Accident Management Company]
			, invol1.tphirecomp_name AS [TP Hire Company]
			, invol1.tpstorereccomp_name AS [TP Storeage Recovery Company]
			, invol1.claimant_name AS [Claimant Name]
			,[SourceSystem]
		FROM #entity_address_list AS AllData
		INNER JOIN red_dw.dbo.dim_matter_header_current AS header ON  
		(CASE WHEN header.ms_fileid = AllData.CaseID THEN 1
			WHEN header.case_id = AllData.CaseID THEN 1
			ELSE 0 END) = 1 
		INNER JOIN red_dw.dbo.fact_dimension_main main ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
		--INNER JOIN red_dw.dbo.fact_dimension_main main ON  AllData.Client = main.client_code COLLATE DATABASE_DEFAULT AND AllData.Matter = main.matter_number COLLATE DATABASE_DEFAULT --- need to join to client code and matter number here after I've got the entity address
		--INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key
		LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
		LEFT JOIN red_dw.dbo.dim_detail_litigation lit ON lit.dim_detail_litigation_key = main.dim_detail_litigation_key
		LEFT JOIN red_dw.dbo.dim_detail_claim claim ON claim.dim_detail_claim_key = main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement invol1 ON invol1.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement invol2 ON invol2.dim_defendant_involvem_key = main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.dim_client_involvement invol3 ON invol3.dim_client_involvement_key = main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_experts_involvement invol4  ON invol4.dim_experts_involvemen_key = main.dim_experts_involvemen_key
	 WHERE main.client_code  NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
	END
	IF @SearchType = 3
	BEGIN

	PRINT CONVERT(VARCHAR(30),GETDATE(),120)

	INSERT INTO #entity_search_results
	SELECT		
			main.client_code							[Client]
			, main.matter_number						[Matter]
			, header.master_client_code +'-'+master_matter_number	AS  [MS Ref]
			, EntityName				  			[Entity Name]
			, header.matter_owner_full_name			[Fee Earner]
			, fed.hierarchylevel4hist				[Team]
			, core.[present_position]       AS      [Present Position] -- Added 19/11/2020 - MT
			, claim.[status]						[Status]
			, header.date_closed_case_management		 [Date Closed]
			, [Address]
			, [InvolvementType]
			
			, RTRIM(ISNULL(core.is_this_a_linked_file,''))	[IsLinkedFile]  
			, RTRIM(ISNULL(core.[is_this_the_lead_file],''))   [IsLeadFile]   
			, RTRIM(ISNULL(core.[lead_file_matter_number_client_matter_number], ''))	[LeadMatterNumber]
			, core.suspicion_of_fraud [Suspicion of Fraud]
			, fraud.fraud_initial_fraud_type AS [Initial Fraud Type]
			, fraud.fraud_current_fraud_type AS [Current Fraud Type]
			, core.credit_hire AS [Credit Hire]
			, fraud.fraud_vehicle_1_registration_number AS [Vehicle Reg Number 1]
			, fraud.fraud_vehicle_2_registration_number AS [Vehicle Reg Number 2]
			, fraud.fraud_ll_claimants_national_insurance_number AS [National Insurance Number]
			, lit.gmc_number AS [GMC Number]
			, core.claimants_date_of_birth [Date of Birth]
			, invol3.insurerclient_reference AS [Insurer Client Ref]
			, invol1.claimantsols_name AS [Claimant Solicitor]
			, invol1.claimantsols_reference AS [Claimant Solicitor Ref]
			, invol2.defendant_name AS [Defendant]
			, invol2.defendant_reference AS [Defendant Ref]
			, invol4.claimantmedexp_name [Claimant Medical Expert]
			, invol1.tpaccmancomp_name AS [TP Accident Management Company]
			, invol1.tphirecomp_name AS [TP Hire Company]
			, invol1.tpstorereccomp_name AS [TP Storeage Recovery Company]
			, invol1.claimant_name AS [Claimant Name]
			,[SourceSystem]
			
		
	    
		FROM #entity_postcode_list AS AllData
		INNER JOIN red_dw.dbo.fact_dimension_main main ON  AllData.Client = main.client_code COLLATE DATABASE_DEFAULT AND AllData.Matter = main.matter_number COLLATE DATABASE_DEFAULT --- need to join to client code and matter number here after I've got the entity address
		INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key
		LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
		LEFT JOIN red_dw.dbo.dim_detail_litigation lit ON lit.dim_detail_litigation_key = main.dim_detail_litigation_key
		LEFT JOIN red_dw.dbo.dim_detail_claim claim ON claim.dim_detail_claim_key = main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement invol1 ON invol1.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement invol2 ON invol2.dim_defendant_involvem_key = main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.dim_client_involvement invol3 ON invol3.dim_client_involvement_key = main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_experts_involvement invol4  ON invol4.dim_experts_involvemen_key = main.dim_experts_involvemen_key
		WHERE main.client_code  NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')

	END
	PRINT CONVERT(VARCHAR(30),GETDATE(),120)


	IF @SearchType NOT IN (1,2,3)
	BEGIN

		INSERT INTO #entity_search_results
		SELECT		
			header.client_code						[Client]
			, header.matter_number					[Matter]
			, header.master_client_code +'-'+master_matter_number	AS  [MS Ref]
			, header.client_name					[Entity Name] -- need to get entity name
			, header.matter_owner_full_name			[Fee Earner]
			, fed.hierarchylevel4hist				[Team]
			, core.[present_position]       AS      [Present Position] -- Added 19/11/2020 - MT
			, claim.[status]						[Status]
			,header.date_closed_case_management		 [Date Closed]
			,'' [Address]
			,'' [InvolvementType]
			
			, RTRIM(ISNULL(core.is_this_a_linked_file,''))	AS [IsLinkedFile]  
			, RTRIM(ISNULL(core.[is_this_the_lead_file],''))  AS [IsLeadFile]   
			, RTRIM(ISNULL(core.[lead_file_matter_number_client_matter_number], ''))	AS [LeadMatterNumber]
			, core.suspicion_of_fraud [Suspicion of Fraud]
			, fraud.fraud_initial_fraud_type AS [Initial Fraud Type]
			, fraud.fraud_current_fraud_type AS [Current Fraud Type]
			, core.credit_hire AS [Credit Hire]
			, fraud.fraud_vehicle_1_registration_number AS [Vehicle Reg Number 1]
			, fraud.fraud_vehicle_2_registration_number AS [Vehicle Reg Number 2]
			, fraud.fraud_ll_claimants_national_insurance_number AS [National Insurance Number]
			, lit.gmc_number AS [GMC Number]
			, core.claimants_date_of_birth AS [Date of Birth]
			, invol3.insurerclient_reference AS [Insurer Client Ref]
			, invol1.claimantsols_name AS [Claimant Solicitor]
			, invol1.claimantsols_reference AS [Claimant Solicitor Ref]
			, invol2.defendant_name AS [Defendant]
			, invol2.defendant_reference AS [Defendant Ref]
			, invol4.claimantmedexp_name [Claimant Medical Expert]
			, invol1.tpaccmancomp_name AS [TP Accident Management Company]
			, invol1.tphirecomp_name AS [TP Hire Company]
			, invol1.tpstorereccomp_name AS [TP Storeage Recovery Company]
			, invol1.claimant_name AS [Claimant Name]
			, ''[SourceSystem]
			
		
	    FROM red_dw.dbo.fact_dimension_main main
		INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
		INNER JOIN @ClientMatter ClientMatter 
			ON ClientMatter.Client = main.client_code COLLATE DATABASE_DEFAULT AND ClientMatter.Matter = main.matter_number COLLATE DATABASE_DEFAULT
		LEFT JOIN red_dw.dbo.dim_detail_fraud fraud ON fraud.dim_detail_fraud_key = main.dim_detail_fraud_key
		LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
		LEFT JOIN red_dw.dbo.dim_detail_litigation lit ON lit.dim_detail_litigation_key = main.dim_detail_litigation_key
		LEFT JOIN red_dw.dbo.dim_detail_claim claim ON claim.dim_detail_claim_key = main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement invol1 ON invol1.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement invol2 ON invol2.dim_defendant_involvem_key = main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.dim_client_involvement invol3 ON invol3.dim_client_involvement_key = main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_experts_involvement invol4  ON invol4.dim_experts_involvemen_key = main.dim_experts_involvemen_key
		WHERE main.client_code  NOT IN ('00121614','00076202'
									,'00047237','00006930'
									,'00123739','00030645'
									,'95000C','00453737')
		


	END


	SELECT 

		[Client] 
			, [Matter] 
			, [MS Ref]
			, [SourceSystem]
			, [Entity Name] 
			, [Fee Earner] 
			, [Team] 
			, [Present Position] -- Added 19/11/2020 - MT
			, [Status] 
			, [Date Closed] 
			, [Address] 
			, [InvolvementType]
			, [IsLinkedFile]
			, [IsLeadFile]  
			, [LeadMatterNumber] 
			, [Suspicion of Fraud] 
			, [Initial Fraud Type] 
			, [Current Fraud Type] 
			, [Credit Hire] 
			, [Vehicle Reg Number 1]
			, [Vehicle Reg Number 2] 
			, [National Insurance Number] 
			, [GMC Number] 
			, [Date of Birth] 
			, [Insurer Client Ref] 
			, [Claimant Solicitor] 
			, [Claimant Solicitor Ref] 
			, [Defendant] 
			, [Defendant Ref] 
			, [Claimant Medical Expert]
			, [TP Accident Management Company]
			, [TP Hire Company]
			, [TP Storeage Recovery Company]
			, [Claimant Name]
			

	FROM #entity_search_results a






	













GO
