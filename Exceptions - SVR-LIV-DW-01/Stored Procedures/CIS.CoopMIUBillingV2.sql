SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [CIS].[CoopMIUBillingV2]
AS
BEGIN
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
    
    
SELECT * INTO #Results
FROM CIS.MIULeadLinkedSnapshot
WHERE InsertedDate=(SELECT MAX(InsertedDate) FROM CIS.MIULeadLinkedSnapshot)
AND [Reporting Level]  IN (2,3)
AND client IN ('00046018','C1001')
AND GuidNumber IS NOT NULL AND lower(GuidNumber) NOT LIKE '%legacy%'





SELECT  
[GuidNumber]
,[CIS Reference]
,ROW_NUMBER() OVER(PARTITION BY [GuidNumber] ORDER BY matter asc) AS Ranking
,[Weightmans Ref]
,[Weightmans Handler]
,[Case Name]
,date_instructions_received AS [TRA094]
,[Date Received]
,[Fraud Status]
,[Litigated?]
,[Fixed Fee?]
,fixed_fee_amount AS [Fixed Fee Amount]
,total_amount_billed AS  [Total Billed To Date]
,defence_costs_billed AS  [Profit costs Billed to date]
,disbursements_billed AS  [Disbursments billed to date]
,last_bill_date AS  [Date of last bill]
,0 AS [Guidtab]
,[Reporting Level]
--,Exceptions
,[Open/Closed Fed]
,[WIP Balance]
,fact_finance_summary.disbursement_balance As  [Disbursements Outstanding]
--,BothStatus
--,Colour
,[Date Closed ARTIION]
,[ARTIION Status]
,ArttionStatusGuid
,[Earliest Date Recieved]
,TotalReserveCurrent
,[Total Guid Numbers]
,GuidProfitCosts
,LeadLinkedStatus
,CASE 
WHEN [Open/Closed Fed]='Open' AND LeadLinkedStatus NOT IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed') AND((ArttionStatusGuid='Open' AND [Earliest Date Recieved] <'2012-10-01') OR (ArttionStatusGuid='Open' AND [Total Guid Numbers] >7) OR (ArttionStatusGuid='Open' AND TotalReserveCurrent>100000 ))THEN 'Hourly Rate' 
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND [Litigated?]='Yes' AND ISNULL(GuidProfitCosts,0) <3250 THEN 'Litigated'
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND (LeadLinkedStatus IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed','Re-opened Claim - From Dormant 50%','Re-opened Claim - From Dormant 95%','Re-opened Claim - from Dormant 50%','Re-opened Claim - from Dormant 95%') AND ISNULL(GuidProfitCosts,0) <1250) THEN '1250 Queries' 
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND ISNULL(GuidProfitCosts,0) <500 AND DATEDIFF(DAY,[Earliest Date Recieved],GETDATE())>30 THEN '500 Queries'
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' THEN 'Fixed Fee'
END  AS SheetNo
,3250-ISNULL(GuidProfitCosts,0) AS [Litigated Amount To Be Billed]
,1250-ISNULL(GuidProfitCosts,0) AS [1250 Amount To Be Billed]
,CASE WHEN ArttionStatusGuid='Open' AND ISNULL(GuidProfitCosts,0) >=3250 AND [Earliest Date Recieved] >='2012-10-01' AND [Litigated?]='Yes' AND LeadLinkedStatus IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed')  THEN 'Yes'
WHEN ArttionStatusGuid='Open' AND ISNULL(GuidProfitCosts,0) >=1250 AND [Earliest Date Recieved] >='2012-10-01' AND ISNULL([Litigated?],'') <>'Yes' AND LeadLinkedStatus IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed')  THEN 'Yes'

END AS [Possible Closures]
,MatterGroup
,GuidWIP

FROM 
(
SELECT  DISTINCT 
NULL case_id
,RTRIM(MIUGovernance.GuidNumber) AS [GuidNumber]
,MIUGovernance.client as client
,MIUGovernance.Matter as matter
,RTRIM([CIS Reference]) AS [CIS Reference]
,ID + ' ' + FeeEarnerCode AS [Weightmans Ref]
,FeeEarner AS [Weightmans Handler]
,matter_description AS [Case Name]
--,TRA094.case_date AS [TRA094]
,[Date Received]
,RTRIM([Status]) AS [Fraud Status]
,[Fixed Fee] AS [Fixed Fee?]
----,FTR058.fixed_fee_amount AS [Fixed Fee Amount]
,[Total Billed To Date] AS [Total Billed To Date]
,[Profit Costs Billed To Date (net of VAT)] [Profit costs Billed to date]
,[Disbursement Costs Billed To Date] AS [Disbursments billed to date]
,[Date Of Last Bill] AS [Date of last bill]
,[Guidtab]
,[Reporting Level]

----,
----ISNULL(CASE WHEN [Fixed Fee]='Yes' AND NMI418.case_text='Yes' AND [Is this the lead file?]='No' THEN 'Fixed Fee Linked Case' END,'')+ ' ' +
----ISNULL(CASE WHEN [Fixed Fee]='No' AND (WIPBal >=100 OR disbursement_balance >0 ) THEN 'Hourly Rate Needs Billing' END,'')+ ' ' +
----ISNULL(CASE WHEN [Date Pleadings Issued]='Yes' AND [Date Received]>'2012-09-30' AND [Total Billed To Date] <3250 THEN 'Billed Less than £3250.00' END,'')+ ' ' +
----ISNULL(CASE WHEN ISNULL([Date Pleadings Issued],'')<>'Yes' AND [Total Billed To Date] <1250 THEN 'Billed Less than £1250.00' END,'')+ ' ' +
----ISNULL(CASE WHEN DATEDIFF(Day,[Date Received],GETDATE()) >30 AND [Total Billed To Date] <500 THEN '£500.00 not billed' END,'')
----AS Exceptions
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS[Open/Closed Fed]
,WIPBal AS [WIP Balance]
,disbursement_balance AS [Disbursements Outstanding]
----,(CASE WHEN [Fixed Fee]='No' AND (WIPBal >=100 OR disbursement_balance >0 ) THEN 1 ELSE 0 END +
----CASE WHEN [Date Pleadings Issued]='Yes' AND [Date Received]>'2012-09-30' AND [Total Billed To Date] <3250 THEN 1 ELSE 0 END + 
----CASE WHEN ISNULL([Date Pleadings Issued],'')<>'Yes' AND [Total Billed To Date] <1250 THEN 1 ELSE 0 END  +
----CASE WHEN [Fixed Fee]='Yes' AND NMI418.case_text='Yes' THEN 1 ELSE 0 END  +
----CASE WHEN DATEDIFF(Day,[Date Received],GETDATE()) >30 AND [Total Billed To Date] <500 THEN 1 ELSE 0 END) AS BothStatus

--,CASE 
--	  WHEN [Fixed Fee]='Yes' AND NMI418.case_text='Yes' AND [Is this the lead file?]='No' THEN 'Purple'WHEN [Fixed Fee]='No' AND (WIPBal >=100 OR disbursement_balance >0 ) THEN 'Green'
--	  WHEN [Date Pleadings Issued]='Yes' AND [Date Received]>'2012-09-30' AND [Total Billed To Date] <3250 THEN 'Yellow'
	  
--      WHEN ISNULL([Date Pleadings Issued],'')<>'Yes' AND [Total Billed To Date] <1250 THEN 'Blue'
--	  WHEN DATEDIFF(Day,[Date Received],GETDATE()) >30 AND [Total Billed To Date] <500 THEN 'Orange' END AS Colour
,date_closed_practice_management AS [Date Closed ARTIION]
,CASE WHEN date_closed_practice_management IS NOT NULL THEN 'Closed' ELSE 'Open' END AS [ARTIION Status]
,CASE WHEN ARTIIONFileStatusOrder=1 THEN 'Open'  WHEN ARTIIONFileStatusOrder=2 THEN 'Closed' END AS ArttionStatusGuid
,EarliestDate AS [Earliest Date Recieved]
,TotalReserve.TotalReserveCurrent AS TotalReserveCurrent
,NoGuidNumber AS [Total Guid Numbers]
,GuidProfitCosts
,LeadLinkedStatus
,NULL AS MatterGroup
,GuidWIP
,PleadingIssuedNew AS [Litigated?]

FROM #Results AS MIUGovernance
INNER JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
 ON MIUGovernance.client=dim_matter_header_current.client_code collate database_default
 AND MIUGovernance.matter=dim_matter_header_current.matter_number collate database_default
LEFT OUTER JOIN
(
SELECT coop_guid_reference_number AS GuidNumber,SUM(disbursement_balance)  AS  disbursement_balance
FROM red_dw.dbo.fact_finance_summary WITH (NOLOCK) 
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON fact_finance_summary.client_code=b.client_code 
 AND fact_finance_summary.matter_number=b.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND fact_finance_summary.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')

	Group by coop_guid_reference_number
) AS Disbs
 ON MIUGovernance.GuidNumber=Disbs.GuidNumber collate database_default
LEFT OUTER JOIN (
SELECT client_code,matter_number,[fixed_fee_amount] FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK) 

) AS FTR058
 ON MIUGovernance.Client=FTR058.client_code collate database_default 
 AND MIUGovernance.Matter=FTR058.matter_number collate database_default
LEFT OUTER JOIN 
(
	SELECT GuidNumber AS PGNGuidNumber,CASE WHEN Min(PleadingIssued)=1 THEN 'Yes' Else 'No' END  AS PleadingIssuedNew
	FROM 
	(
SELECT GuidNumber,Min(PleadingIssued) AS PleadingIssued
	FROM 
	(	
SELECT coop_guid_reference_number AS GuidNumber,proceedings_issued  AS TRA082
	,CASE WHEN proceedings_issued='Yes' THEN 1
	WHEN proceedings_issued='No' THEN 2 END AS PleadingIssued
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_court WITH (NOLOCK)
  ON a.dim_detail_court_key=dim_detail_court.dim_detail_court_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')

	) As PleadingIssued
	Group by GuidNumber
	) As PleadingIssued
	Group by GuidNumber
) AS PleadingIssued1
 ON MIUGovernance.GuidNumber=PleadingIssued1.PGNGuidNumber collate database_default

	LEFT OUTER JOIN
	(
		SELECT GuidNumber,Min(FileStatusOrder) AS ARTIIONFileStatusOrder
	FROM 
	(	
SELECT coop_guid_reference_number AS GuidNumber,CASE WHEN date_closed_practice_management IS NULL  THEN     1
		WHEN date_closed_practice_management IS NOT NULL THEN 2
		END AS FileStatusOrder
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current  WITH (NOLOCK) 
 ON a.client_code=dim_matter_header_current.client_code
 AND   a.matter_number=dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
	) As PleadingIssued
	Group by GuidNumber
		) As ArttionStatus
	 ON MIUGovernance.GuidNumber=ArttionStatus.GuidNumber  collate database_default
LEFT OUTER JOIN
	(
	SELECT GuidNumber AS ArtiionGuid,Min(date_instructions_received)AS EarliestDate
	FROM 
	(	
SELECT coop_guid_reference_number AS GuidNumber,date_instructions_received  AS date_instructions_received
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
	) As PleadingIssued
	Group by GuidNumber
		) As EarliestDateRecieved
	 ON MIUGovernance.GuidNumber=EarliestDateRecieved.ArtiionGuid	 collate database_default 
LEFT OUTER JOIN (SELECT client_code,matter_number,is_this_a_linked_file AS case_text FROM red_dw.dbo.dim_detail_core_details WITH(NOLOCK) WHERE is_this_a_linked_file IS NOT NULL) AS NMI418
 ON MIUGovernance.Client=NMI418.client_code  collate database_default
 AND  MIUGovernance.Matter=NMI418.matter_number  collate database_default

LEFT OUTER JOIN (SELECT GuidNumber AS RGuidNo,ISNULL([Damages Reserve Held LeadLinked],0) +ISNULL([Opponents Costs Reserve Held LeadLinked],0) +ISNULL([Defence Costs Reserve Held LeadLinked],0) AS TotalReserveCurrent
 FROM CIS.MIULeadLinkedSnapshot
WHERE [Reporting Level]=1 AND GuidNumber NOT LIKE '%Legacy%'
AND InsertedDate=(SELECT MAX(InsertedDate) FROM CIS.MIULeadLinkedSnapshot)
) AS TotalReserve
 ON MIUGovernance.GuidNumber=TotalReserve.RGuidNo

LEFT OUTER JOIN (SELECT GuidNumber AS GGNo,COUNT(GuidNumber) AS NoGuidNumber
FROM   CIS.MIULeadLinkedSnapshot
WHERE [Reporting Level]  IN (2,3)
AND InsertedDate=(SELECT MAX(InsertedDate) FROM CIS.MIULeadLinkedSnapshot)
GROUP BY GuidNumber) AS GGno
 ON MIUGovernance.GuidNumber=GGNo.GGNo
LEFT OUTER JOIN (
SELECT coop_guid_reference_number AS PGuidNo,SUM(defence_costs_billed) AS GuidProfitCosts  FROM red_dw.dbo.fact_finance_summary
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON fact_finance_summary.client_code=dim_detail_core_details.client_code
 AND  fact_finance_summary.matter_number=dim_detail_core_details.matter_number
WHERE fact_finance_summary.client_code <>'C1001'
GROUP BY coop_guid_reference_number 
) AS GuidProfitCosts
 ON MIUGovernance.GuidNumber=GuidProfitCosts.PGuidNo collate database_default

LEFT OUTER JOIN (

SELECT GuidNumber AS PGuidNo,SUM(WIPBal) AS GuidWIP
 FROM CIS.MIULeadLinkedSnapshot
WHERE [Reporting Level]<>1 AND GuidNumber NOT LIKE '%Legacy%'
AND InsertedDate=(SELECT MAX(InsertedDate) FROM CIS.MIULeadLinkedSnapshot)
GROUP BY GuidNumber
) AS GuidWIP
 ON MIUGovernance.GuidNumber=GuidWIP.PGuidNo
LEFT OUTER JOIN (SELECT GuidNumber AS SGuidNo,[Status] AS LeadLinkedStatus
FROM CIS.MIULeadLinkedSnapshot
WHERE [Reporting Level]=1 AND GuidNumber NOT LIKE '%Legacy%'
AND InsertedDate=(SELECT MAX(InsertedDate) FROM CIS.MIULeadLinkedSnapshot)
) AS LeadLinkedStatus
 ON MIUGovernance.GuidNumber=LeadLinkedStatus.SGuidNo
 
 ) AS AllData
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON AllData.client=fact_finance_summary.client_code collate database_default
 AND AllData.matter=fact_finance_summary.matter_number collate database_default
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON AllData.client=dim_detail_core_details.client_code collate database_default
 AND AllData.matter=dim_detail_core_details.matter_number collate database_default

LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON AllData.client=fact_matter_summary_current.client_code collate database_default
 AND AllData.matter=fact_matter_summary_current.matter_number collate database_default 

WHERE ISNULL([Fraud Status],'') <>'Transferred File'
AND (CASE 
WHEN [Open/Closed Fed]='Open' AND LeadLinkedStatus NOT IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed') AND((ArttionStatusGuid='Open' AND [Earliest Date Recieved] <'2012-10-01') OR (ArttionStatusGuid='Open' AND [Total Guid Numbers] >7) OR (ArttionStatusGuid='Open' AND TotalReserveCurrent>100000 ))THEN 'Hourly Rate' 
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND [Litigated?]='Yes' AND ISNULL(GuidProfitCosts,0) <3250 THEN 'Litigated'
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND (LeadLinkedStatus IN ('Dormant - 95% Confidence','Dormant - 50% Confidence','Legally Closed','Re-opened Claim - From Dormant 50%','Re-opened Claim - From Dormant 95%','Re-opened Claim - from Dormant 50%','Re-opened Claim - from Dormant 95%') AND ISNULL(GuidProfitCosts,0) <1250) THEN '1250 Queries' 
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' AND ISNULL(GuidProfitCosts,0) <500 AND DATEDIFF(DAY,[Earliest Date Recieved],GETDATE())>30 THEN '500 Queries'
WHEN ArttionStatusGuid='Open' AND [Earliest Date Recieved] >='2012-10-01' THEN 'Fixed Fee'
END)='Litigated'
--AND [Weightmans Ref]='46018-46304 4195'




END
GO
