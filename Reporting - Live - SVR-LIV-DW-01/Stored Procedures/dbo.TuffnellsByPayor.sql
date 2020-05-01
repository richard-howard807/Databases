SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[TuffnellsByPayor]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS

BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE

--SET @StartDate='2020-01-01'
--SET @EndDate='2020-04-17'

SELECT RTRIM(red_dw.dbo.dim_matter_header_current.client_code) +'-'+ RTRIM(red_dw.dbo.dim_matter_header_current.matter_number) AS [Client & Matter Ref]
,matter_description AS [Matter Description]
,insurerclient_reference AS [Insured Reference]
,name AS [Matter Owner]
,date_opened_case_management AS [Date Opened]
,InvNumber AS [Invoice Number]
,OrgHCo + OrgSCo AS [Disbursements]
,OrgFee AS Revenue
,OrgAmt - OrgTax AS [Net Bill Amount]
,OrgAmt AS [Gross Bill Amount]
,InvDate AS [Bill Date]
,OrgTax AS [Vat]
,NULL AS [Payor]
,FinalBill AS FinalBill
FROM TE_3E_Prod.dbo.InvMaster
LEFT OUTER JOIN MS_Prod.config.dbFile
 ON LeadMatter=fileExtLinkID
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN (SELECT bill_number,CASE WHEN bill_flag='f' THEN 'Yes' ELSE 'No'  END AS FinalBill
,ROW_NUMBER() OVER(PARTITION BY bill_number       ORDER BY (CASE WHEN bill_flag='f' THEN 1 ELSE 2 END) DESC) xOrder

FROM red_dw.dbo.dim_bill) AS FinalBill
 ON InvNumber=FinalBill.bill_number COLLATE DATABASE_DEFAULT AND FinalBill.xOrder=1
WHERE InvIndex IN (
SELECT InvMaster FROM TE_3E_Prod.dbo.ARDetail
INNER JOIN  TE_3E_Prod.dbo.Payor ON ARDetail.Payor=Payor.PayorIndex
WHERE 
(
UPPER(Payor.DisplayName) LIKE '%CONNECT GROUP%'
OR UPPER(Payor.DisplayName) LIKE '%BIG GREEN%'
OR UPPER(Payor.DisplayName) LIKE '%Tuffnells%'
OR UPPER(Payor.DisplayName) LIKE '%SMITH NEWS%'
) )
AND InvDate BETWEEN @StartDate AND @EndDate
AND IsReversed=0
AND InvNumber<>'PURGE'

END
--SELECT RTRIM(red_dw.dbo.dim_matter_header_current.client_code) +'-'+ RTRIM(red_dw.dbo.dim_matter_header_current.matter_number) AS [Client & Matter Ref]
--,matter_description AS [Matter Description]
--,insurerclient_reference AS [Insured Reference]
--,name AS [Matter Owner]
--,date_opened_case_management AS [Date Opened]
--,InvNumber AS [Invoice Number]
--,ARHCo + ARSCo AS [Disbursements]
--,ARDetail.ARFee AS Revenue
--,ARAmt - ARTAx AS [Net Bill Amount]
--,ARAmt AS [Gross Bill Amount]
--,ARDetail.InvDate AS [Bill Date]
--,ARTAx AS [Vat]
--,Payor.DisplayName AS [Payor]
--,FinalBill AS FinalBill

--FROM TE_3E_Prod.dbo.ARDetail WITH (NOLOCK)
--INNER JOIN TE_3E_Prod.dbo.InvMaster
-- ON ARDetail.InvMaster=InvMaster.InvIndex
--INNER JOIN TE_3E_Prod.dbo.Matter WITH (NOLOCK) 
-- ON ARDetail.Matter=Matter.MattIndex
--INNER JOIN TE_3E_Prod.dbo.Client
-- ON Matter.Client=Client.ClientIndex
--LEFT OUTER JOIN TE_3E_Prod.dbo.Payor ON ARDetail.Payor=Payor.PayorIndex
--LEFT OUTER JOIN MS_Prod.config.dbFile
-- ON MattIndex=fileExtLinkID
--LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
-- ON fileID=ms_fileid
--LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
-- ON dim_client_involvement.client_code = dim_matter_header_current.client_code
-- AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
-- ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
--LEFT OUTER JOIN (SELECT bill_number,CASE WHEN bill_flag='F' THEN 'Yes' ELSE 'No'  END AS FinalBill
--,ROW_NUMBER() OVER(PARTITION BY bill_number       ORDER BY (CASE WHEN bill_flag='F' THEN 1 ELSE 2 END) DESC) xOrder

--FROM red_dw.dbo.dim_bill) AS FinalBill
-- ON InvNumber=FinalBill.bill_number COLLATE DATABASE_DEFAULT AND FinalBill.xOrder=1
GO
