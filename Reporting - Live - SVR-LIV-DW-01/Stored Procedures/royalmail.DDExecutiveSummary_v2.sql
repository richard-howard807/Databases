SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [royalmail].[DDExecutiveSummary_v2]
AS
begin

SELECT 
AllData.*,
CASE WHEN [Delivery Office (DO)]='Yes' THEN 'Red'
WHEN [Vehicle Park (PAR)]='Yes' THen 'Yellow' 
WHEN [Office (OFF)]='Yes' THEN 'Green' 
WHEN [Road Trans WS (WS)]='Yes' THEN 'Blue' 
WHEN [Crown Office (CO)]='Yes' THEN 'Purple' 
WHEN [Storage (ST)]='Yes' THEN 'Brown' 
WHEN [Mail Centre (MC)]='Yes' THEN 'Teal'
WHEN [Industrial (IND)]='Yes' THEN 'Orange' 
WHEN [Garage (GAR)]='Yes' THEN 'Pink' 
WHEN [Retail (RET)]='Yes' THEN 'Sea Green' 
END as MapColour
,CASE WHEN Country IN ('Northern Ireland','Scotland') THEN NULL 
	  WHEN Tenure IN ('Leasehold as Landlord <15k','Leasehold as Tenant 1-25k') THEN NULL 
	  WHEN LinkRemoval IS NOT NULL THEN NULL
	  ELSE 
'https://rmg.myweightmans.com/activities.aspx?matterid=' + rtrim(cast([niMatterID]as varchar(50))) END as 
--,'https://rmg.myweightmans.com/' as
MyWeightmansMatterLink
,CASE WHEN [Tenure]='Leasehold as Landlord 15k+' AND TitleExclusion='Include' THEN 1 ELSE 0 END  AS LeaseholdLandlordCount
,CASE WHEN [Tenure]='Leasehold as Landlord 15k+' AND TitleExclusion='Include' THEN [Rental Value] ELSE NULL END AS LandlordRent
,CASE WHEN ([Tenure]='Leasehold as Tenant >25k' OR [Tenure]='Leasehold as Tenant >100k') AND TitleExclusion='Include' THEN 1 ELSE 0 END  AS LeaseholdTenantCount
,CASE WHEN ([Tenure]='Leasehold as Tenant >25k' OR [Tenure]='Leasehold as Tenant >100k') AND TitleExclusion='Include' THEN [Rental Value] ELSE NULL END AS TenantRent
,CASE WHEN ([Tenure]='Leasehold as Tenant >25k') AND TitleExclusion='Include' THEN 1 ELSE 0 END  AS [LeaseholdTenant25Count]
,CASE WHEN ([Tenure]='Leasehold as Tenant >25k') AND TitleExclusion='Include' THEN [Rental Value] ELSE NULL END AS [25TenantRent]
,CASE WHEN ([Tenure]='Leasehold as Tenant >100k') AND TitleExclusion='Include' THEN 1 ELSE 0 END  AS [LeaseholdTenant100Count]
,CASE WHEN ([Tenure]='Leasehold as Tenant >100k') AND TitleExclusion='Include' THEN [Rental Value] ELSE NULL END AS [100TenantRent]

 FROM 
( 
SELECT  
case_id
,[BE No]
,[BE Name] AS [BE Name]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% BAG %' THEN 'Yes' ELSE 'No' END AS [Bag Depot (BAG)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% CO %' THEN 'Yes' ELSE 'No' END AS [Crown Office (CO)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% OFF %' THEN 'Yes' ELSE 'No' END AS [Office (OFF)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% DO %' THEN 'Yes' ELSE 'No' END AS [Delivery Office (DO)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% CIT %' THEN 'Yes' ELSE 'No' END AS [Cash in Transit (CIT)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% RTW %' THEN 'Yes' ELSE 'No' END AS [Road Trans WS (WS)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% MED %' THEN 'Yes' ELSE 'No' END AS [Medical Unit (MED)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% GAR %' THEN 'Yes' ELSE 'No' END AS [Garage (GAR)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% IND %' THEN 'Yes' ELSE 'No' END AS [Industrial (IND)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% LAN %' THEN 'Yes' ELSE 'No' END AS [Land (LAN)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% PAR %' THEN 'Yes' ELSE 'No' END AS [Vehicle Park (PAR)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% RES %' THEN 'Yes' ELSE 'No' END AS [Residential (RES)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% RET %' THEN 'Yes' ELSE 'No' END AS [Retail (RET)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% ST %' THEN 'Yes' ELSE 'No' END AS [Storage (ST)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% DMB %' THEN 'Yes' ELSE 'No' END AS [Desk Managed Branch (DMB)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% DSK %' THEN 'Yes' ELSE 'No' END AS [Desk (DSK)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% PO %' THEN 'Yes' ELSE 'No' END AS [PO (PO)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% HUB %' THEN 'Yes' ELSE 'No' END AS [Rd/Rail/Air Hub (HUB)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% MSP %' THEN 'Yes' ELSE 'No' END AS [Mod Sub PO (MSP)]
--,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% SSC %' THEN 'Yes' ELSE 'No' END AS SSC
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% EO %' THEN 'Yes' ELSE 'No' END AS [Enquiry Office (EO)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% LD %' THEN 'Yes' ELSE 'No' END AS [Local Depot (LD)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% MC %' THEN 'Yes' ELSE 'No' END AS [Mail Centre (MC)]
--,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% AN %' THEN 'Yes' ELSE 'No' END AS AN
--,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% ED %' THEN 'Yes' ELSE 'No' END AS ED
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% MDC %' THEN 'Yes' ELSE 'No' END AS [Data Centre (MDC)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% MHR %' THEN 'Yes' ELSE 'No' END AS [Minor Hire (MHR)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% PRO %' THEN 'Yes' ELSE 'No' END AS [PO Railway (PRO)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% RDC %' THEN 'Yes' ELSE 'No' END AS [Reg Dist Centre (RDC)]
--,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% C %' THEN 'Yes' ELSE 'No' END AS C
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% VOC %' THEN 'Yes' ELSE 'No' END AS [Vehicle Operating Centre (VOC)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% SPD %' THEN 'Yes' ELSE 'No' END AS [Scale Payment DO (SPD)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% TC %' THEN 'Yes' ELSE 'No' END AS [Training College (TC)]
,CASE WHEN REPLACE(([BE Name]+'/'),'/',' ') LIKE '% FPO %' THEN 'Yes' ELSE 'No' END AS [Franchise Post Office (FPO)]
,[Address]
,[PostCode]
,[Region]
 , Case when [RU Type] = 'BAG' then 'Bag Depot'
 when [RU Type] = 'CHR' then 'Christmas Hire'
 when [RU Type] = 'CIT' then 'Cash in Transit'
 when [RU Type] = 'CO' then 'Crown Office'
 when [RU Type] = 'DO' then 'Delivery Office'
 when [RU Type] = 'FPO' then 'Franchise Post Office'
 when [RU Type] = 'GAR' then 'Garage'
 when [RU Type] = 'HUB' then 'Rd/Rail/Air Hub'
 when [RU Type] = 'IND' then 'Industrial'
 when [RU Type] = 'LAN' then 'Land'
 when [RU Type] = 'LD' then 'Local Depot'
 when [RU Type] = 'MC' then 'Mail Centre'
 when [RU Type] = 'MDC' then 'Data Centre'
 when [RU Type] = 'MED' then 'Medical Unit'
 when [RU Type] = 'MHR' then 'Minor Hire'
 when [RU Type] = 'MSP' then 'Mod Sub PO'
 when [RU Type] = 'OFF' then 'Office'
 when [RU Type] = 'PAR' then 'Vehicle Park'
 when [RU Type] = 'PMS' then 'Paper/Metal Store'
 when [RU Type] = 'PRO' then 'PO Railway'
 when [RU Type] = 'RDC' then 'Reg Dist Centre'
 when [RU Type] = 'RES' then 'Residential'
 when [RU Type] = 'RET' then 'Retail'
 when [RU Type] = 'RTW' then 'Road Trans WS'
 when [RU Type] = 'SPD' then 'Scale Payment DO'
 when [RU Type] = 'ST' then 'Storage'
 when [RU Type] = 'VOC' then 'Vehicle Operating Centre'
 when [RU Type] = 'WIL' then 'Williames, (Irish property)'
 when [RU Type] = 'EO' then 'Enquiry Office'
 when [RU Type] = 'TC' then 'Training College'
 when [RU Type] = 'DSK' then 'Desk'
 when [RU Type] = 'DMB' then 'Desk Managed Branch'
 
 else [RU Type] end as [Rental Unit Types]
,[Tenure]
,[Rental Value - payable]
,[Rental Value - receivable]
,CASE WHEN ISNUMERIC(RTRIM(Reporting.dbo.fn_StripCharacters([Rental Value], 'a-Z')))=1 THEN RTRIM(Reporting.dbo.fn_StripCharacters([Rental Value], 'a-Z')) ELSE NULL END AS [Rental Value]
,CASE WHEN Tenure='Freehold' THEN NULL ELSE (CASE WHEN CAST(datediff(year,getdate(),[Term remaining]) AS Decimal(10,2)) <0 THEN 'Expired'
 WHEN CAST(datediff(year,getdate(),[Term remaining]) AS Decimal(10,2)) BETWEEN 0 AND 2 THEN '0-2 Years'
 WHEN CAST(datediff(year,getdate(),[Term remaining]) AS Decimal(10,2)) > 2  AND CAST(datediff(year,getdate(),[Term remaining]) AS Decimal(10,2)) <=5.00 THEN '2-5 Years'
 WHEN CAST(datediff(year,getdate(),[Term remaining]) AS Decimal(10,2)) > 5.00  THEN '>5 Years'  ELSE NULL END)END AS [Term remaining]
,[Assignment]
,[Subletting]
,[Structural alterations]
,[Non-Structural alterations]
,CASE WHEN datediff(Month,getdate(),[Landlord Break]) Between 0 AND  24 THEN '0-2 Years'
WHEN datediff(Month,getdate(),[Landlord Break]) >24  AND  datediff(Month,getdate(),[Landlord Break])<=60 THEN '>2-5 Years' 
WHEN datediff(Month,getdate(),[Landlord Break])>60 THEN '>5 Years' 
ELSE 'No Break' 
END AS [Landlord Break]
,CASE WHEN datediff(Month,getdate(),[Tenant Break]) Between 0 AND  24 THEN '0-2 Years'
WHEN datediff(Month,getdate(),[Tenant Break]) >24  AND  datediff(Month,getdate(),[Tenant Break])<=60 THEN '>2-5 Years' 
WHEN datediff(Month,getdate(),[Tenant Break])>60 THEN '>5 Years' 
ELSE 'No Break' 
END AS [Tenant Break]
,[LTA 1954]
,[Yield Up]
, case when [Alterations] like 'Reinstatement%' then 'Reinstatement' when [Alterations] like 'No rein%' then 'No Reinstatement' else NULL end as [Alterations]
,CaseNumber
,ROW_NUMBER()  OVER(PARTITION BY [BE No] ORDER BY [BE No]) AS MultipleMatter
,CASE WHEN datediff(Month,getdate(),[Next Review Date]) Between 0 AND  24 THEN '0-2 Years'
WHEN datediff(Month,getdate(),[Next Review Date]) >24  AND  datediff(Month,getdate(),[Next Review Date])<=60 THEN '>2-5 Years' 
WHEN datediff(Month,getdate(),[Next Review Date])>60 THEN '>5 Years' 
ELSE 'No Review' 
END AS [Next Review Date]
,ChangeControl as [Change of Control]
,TitleExclusion
,Country
,LinkRemoval
 FROM (
--FREEHOLD Titles

SELECT be_number [BE No],
       be_name [BE Name],
       property_address [Address],
       postcode [PostCode],
       PRO825.case_text [Region],
       '' AS [RU Type],
       'Freehold' AS [Tenure],
       NULL AS [Rental Value - payable],
       NULL AS [Rental Value - receivable],
       NULL AS [Rental Value],
       NULL AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       '' AS ChangeControl,
       1 AS CaseNumber,
       PRO835.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       NULL AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO835
        ON PRO835.case_id = cashdr.case_id
           AND PRO835.case_detail_code = 'PRO835'
           AND PRO835.current_flag = 'Y'
--
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND PRO835.case_text IS NOT NULL
	  union All
--LONGLEASE
SELECT be_number,
       be_name,
       property_address,
       postcode,
       PRO825.case_text region,
       '' AS [RU Type],
       'Freehold' AS [Tenure],
       NULL AS [Rental Value - payable],
       NULL AS [Rental Value - receivable],
       NULL AS [Rental Value],
       NULL AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       '' AS ChangeControl,
       1 AS CaseNumber,
       PRO835.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       NULL AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO835
        ON PRO835.case_id = cashdr.case_id
           AND PRO835.case_detail_code = 'PRO835'
           AND PRO835.current_flag = 'Y'
    --
    LEFT JOIN Reporting.dbo.RMLeaseLongAllRecords
        ON cashdr.case_id = RMLeaseLongAllRecords.case_id
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND RMLeaseLongAllRecords.case_id IS NOT NULL
--LET PORTFOLIO
union All
SELECT 
be_number,
be_name,
property_address,
postcode,
PRO825.case_text region,
'' AS [RU Type],
'Leasehold as Landlord 15k+' AS [Tenure],
NULL AS [Rental Value - payable],
'£15k' AS [Rental Value - receivable],
CAST(Reporting.[dbo].ufn_GetNumbersFromString(RTRIM(
CASE WHEN (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Originalrent,'per year',''),'per month exclusive of VAT',''),'for the term','')
,'(if demanded)',''),'A peppercorn',''),'peppercorn',''),'Peppercorn',''),'.00',''))='' 
THEN NULL ELSE 
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Originalrent,'per year',''),'per month exclusive of VAT',''),'for the term','')
,'(if demanded)',''),'A peppercorn',''),'peppercorn',''),'Peppercorn',''),'.00','') END) ) AS NUMERIC) AS [Rental Value]
,[Term End Date] AS [Term remaining]
,CASE WHEN Assignment='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Assignment]
,CASE WHEN Underletting='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Subletting]
,CASE WHEN PRO991='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Structural alterations]
,CASE WHEN PRO992 ='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Non-Structural alterations]
,Breaks.LandlordBreak AS  [Landlord Break]
,Breaks.TenantBreak AS [Tenant Break]
,Case when PRO1261.case_text in ('Scotland', 'Northern Ireland') then 'N/A - Scotland & NI' else [LTA1954] end AS [LTA 1954]
,CASE WHEN PRO993 ='No specified condition' OR  PRO993='No specific condition' THEN 'No Repair' ELSE 'Repair'  END AS [Yield Up]
,PRO994 AS [Alterations]
,Nextreviewdate AS [Next Review Date]
,'Not Reviewed' AS ChangeControl
,1 AS CaseNumber
,Data.case_id as case_id
,'include let portfolio' AS TitleExclusion
, PRO1261.case_text as Country
,NULL AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN Reporting.dbo.RMLetPortfolioAllRecords Data
        ON cashdr.case_id = Data.case_id
		LEFT OUTER JOIN Reporting.dbo.RMLetBreakDates AS Breaks
on Data.case_id=Breaks.case_id
AND Data.TitleNumber=Breaks.[Expr1] collate database_default
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND Data.case_id IS NOT NULL
	  AND ([Term Start Date] <=CONVERT(DATE,getdate(),103) OR [Term Start Date] IS NULL)

 --25 TO 100K
union All

SELECT 
be_number,
be_name,
property_address,
postcode,
PRO825.case_text region,
'' AS [RU Type],
'Leasehold as Tenant 25k - 100k' AS [Tenure],
'£25 - £100k' AS [Rental Value - payable],
Null AS [Rental Value - receivable]
, NewRentalValue [Rental Value]
,[Term End Date] AS [Term remaining]
,CASE WHEN Assignment='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Assignment]
,CASE WHEN Underletting='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Subletting]
,CASE WHEN PRO985='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Structural alterations]
,CASE WHEN PRO986 ='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Non-Structural alterations]
,Breaks.LandlordBreak AS  [Landlord Break]
,Breaks.TenantBreak AS [Tenant Break]
,Case when PRO1261.case_text in ('Scotland', 'Northern Ireland') then 'N/A - Scotland & NI' else [LTA1954] end AS [LTA 1954]
,CASE WHEN PRO987 ='No specified condition' OR  PRO987='No specific condition' THEN 'No Repair' ELSE 'Repair'  END AS [Yield Up]
,PRO988 AS [Alterations]
,Nextreviewdate AS [Next Review Date]
,'Not Reviewed' AS ChangeControl
,1 AS CaseNumber
,Data.case_id as case_id
,'include' AS TitleExclusion
, PRO1261.case_text as Country
,NULL AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN (SELECT * FROM Reporting.dbo.RMLease25100kAllRecords WHERE ISNUMERIC(TitleNumber) = 1) As Data
        ON cashdr.case_id = Data.case_id
		LEFT OUTER JOIN Reporting.dbo.RMLetBreakDates AS Breaks
on Data.case_id=Breaks.case_id
AND Data.TitleNumber=Breaks.[Expr1] collate database_default
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
	  AND ([Term Start Date] <=CONVERT(DATE,getdate(),103) OR [Term Start Date] IS NULL)
      AND Data.case_id IS NOT NULL
union All	                                           
--100k PLUS 
SELECT 
be_number,
be_name,
property_address,
postcode,
PRO825.case_text region,
'' AS [RU Type],
'Leasehold as Tenant >100k' AS [Tenure],
'£100k+' AS [Rental Value - payable],
Null AS [Rental Value - receivable]
, NewRentalValue [Rental Value]
,[Term End Date] AS [Term remaining]
,CASE WHEN AssignWhole='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Assignment]
,CASE WHEN UnderletWhole='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Subletting]
,CASE WHEN structuralandexternal1='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Structural alterations]
,CASE WHEN internal1 ='Not permitted' THEN 'Not Permitted' ELSE 'Permitted' END AS [Non-Structural alterations]
,PlusBreaks.LandlordBreak AS  [Landlord Break]
,PlusBreaks.TenantBreak AS [Tenant Break]
,Case when PRO1261.case_text in ('Scotland', 'Northern Ireland') then 'N/A - Scotland & NI' else [LTA1954] end AS [LTA 1954]
,CASE WHEN PRO960 ='No specified condition' OR  PRO960='No specific condition' THEN 'No Repair' ELSE 'Repair'  END AS [Yield Up]
,PRO998 AS [Alterations]
,Nextreviewdate AS [Next Review Date]
,CASE WHEN PRO958='Not permitted' THEN 'Not Permitted' WHEN PRO958 is null then 'Not Reviewed' ELSE 'Permitted' END  AS ChangeControl
,1 AS CaseNumber
,Data.case_id as case_id
,'include' AS TitleExclusion
, PRO1261.case_text as Country
,NULL AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN Reporting.dbo.RMLease100kAllRecords As Data
        ON cashdr.case_id = Data.case_id
		LEFT OUTER JOIN Reporting.dbo.RM100PlusBreakDates AS PlusBreaks
on Data.case_id=PlusBreaks.case_id
ANd Data.TitleNumber=PlusBreaks.TitleNumber collate database_default
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
	  AND ([Term Start Date] <=CONVERT(DATE,getdate(),103) OR [Term Start Date] IS NULL)
      AND Data.case_id IS NOT NULL

union All
--Freehold Sample'
SELECT be_number,
       be_name,
       property_address,
       postcode,
       PRO825.case_text region,
       '' AS [RU Type],
       'Freehold' AS [Tenure],
       NULL AS [Rental Value - payable],
       NULL AS [Rental Value - receivable],
       NULL AS [Rental Value],
       NULL AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       '' AS ChangeControl,
       1 AS CaseNumber,
       PRO937.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       'Freehold Sample' AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO937
        ON PRO937.case_id = cashdr.case_id
           AND PRO937.case_detail_code = 'PRO937'
           AND PRO937.current_flag = 'Y'
--
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND PRO937.case_value > 0 
union All
--Leasehold as Landlord <15k'
SELECT be_number,
       be_name,
       property_address,
       postcode,
       PRO825.case_text region,
       '' AS [RU Type],
       'Leasehold as Landlord <15k' AS [Tenure],
       NULL AS [Rental Value - payable],
       '' AS [Rental Value - receivable],
       NULL AS [Rental Value],
       '' AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       'Not Reviewed' AS ChangeControl,
       1 AS CaseNumber,
       PRO1027.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       Null AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1027
        ON PRO1027.case_id = cashdr.case_id
           AND PRO1027.case_detail_code = 'PRO1027'
           AND PRO1027.current_flag = 'Y'
--
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND PRO1027.case_value > 0 
union All

--Leasehold as Tenant 1-25k
SELECT be_number,
       be_name,
       property_address,
       postcode,
       PRO825.case_text region,
       '' AS [RU Type],
       'Leasehold as Tenant 1-25k' AS [Tenure],
       NULL AS [Rental Value - payable],
       '' AS [Rental Value - receivable],
       NULL AS [Rental Value],
       '' AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       'Not Reviewed' AS ChangeControl,
       1 AS CaseNumber,
       PRO1028.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       Null AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1028
        ON PRO1028.case_id = cashdr.case_id
           AND PRO1028.case_detail_code = 'PRO1028'
           AND PRO1028.current_flag = 'Y'
--
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
      AND PRO1028.case_value > 0 

--case_id filtered
union All
SELECT be_number,
       be_name,
       property_address,
       postcode,
       PRO825.case_text region,
       '' AS [RU Type],
       CASE WHEN PRO1028.case_value >0 THEN 'Leasehold as Tenant 1-25k'
WHEN PRO939.case_value >0 THEN 'Leasehold as Tenant 25k - 100k'
WHEN PRO940.case_value >0 THEN 'Leasehold as Tenant >100k'
WHEN PRO1027.case_value >0 THEN 'Leasehold as Landlord <15k'
WHEN PRO941.case_value>0 THEN 'Leasehold as Landlord 15k+'
ELSE 'Freehold' END AS [Tenure],
       NULL AS [Rental Value - payable],
       '' AS [Rental Value - receivable],
       NULL AS [Rental Value],
       '' AS [Term remaining],
       '' AS [Assignment],
       '' AS [Subletting],
       '' AS [Structural alterations],
       '' AS [Non-Structural alterations],
       NULL AS [Landlord Break],
       NULL AS [Tenant Break],
       '' AS [LTA 1954],
       '' AS [Yield Up],
       '' AS [Alterations],
       NULL AS [Next Review Date],
       '' AS ChangeControl,
       1 AS CaseNumber,
       cashdr.case_id AS case_id,
       'exclude' AS TitleExclusion,
       PRO1261.case_text AS Country,
       Null AS LinkRemoval
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    --to be removed once details in warehouse
    LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
        ON cashdr.client = fact_dimension_main.client_code
           AND cashdr.matter = fact_dimension_main.matter_number
           AND cashdr.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO825
        ON PRO825.case_id = cashdr.case_id
           AND PRO825.case_detail_code = 'PRO825'
           AND PRO825.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1261
        ON PRO1261.case_id = cashdr.case_id
           AND PRO1261.case_detail_code = 'PRO1261'
           AND PRO1261.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO829
        ON PRO829.case_id = cashdr.case_id
           AND PRO829.case_detail_code = 'PRO829'
           AND PRO829.current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1028
        ON PRO1028.case_id = cashdr.case_id
           AND PRO1028.case_detail_code = 'PRO1028'
           AND PRO1028.current_flag = 'Y'

		LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO939
        ON PRO939.case_id = cashdr.case_id
           AND PRO939.case_detail_code = 'PRO939'
           AND PRO939.current_flag = 'Y'
		LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO940
        ON PRO940.case_id = cashdr.case_id
           AND PRO940.case_detail_code = 'PRO940'
           AND PRO940.current_flag = 'Y'
		LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO1027
        ON PRO1027.case_id = cashdr.case_id
           AND PRO1027.case_detail_code = 'PRO1027'
           AND PRO1027.current_flag = 'Y'
		LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet PRO941
        ON PRO941.case_id = cashdr.case_id
           AND PRO941.case_detail_code = 'PRO941'
           AND PRO941.current_flag = 'Y'
--
WHERE (
          PRO829.case_text IS NULL
          OR PRO829.case_text <> 'Withdrawn'
      )
      AND fact_dimension_main.client_code = 'P00016'
	  AND cashdr.case_id in 
(
'391479','391664','391691','391709','391743','391747','391758','391764'
,'391776','391786','391803','391805','391807','391810','391811','391815'
,'391817','391818','391819','391820','391821','391824','391825','391827'
,'391968','392005','392009','422572','422573','422574','422575','422576'
,'422577','422578','422579','422580','422581','422582','422583','422584'
,'422585','422586','422587','422588','422589','422590','422591','422592'
,'391218'

) and cashdr.matter <> 'ML'

--SELECT statement
)AS CombinedData
 ) AS AllData
LEFT OUTER JOIN red_dw.dbo.ds_sh_axxia_cashdr as cashdr
on AllData.case_id=cashdr.case_id AND cashdr.current_flag = 'Y'
LEFT JOIN (select [niMatterID],[sClientCode],[sMatterCode] from [DMZ-SQL01SVR].[eCase].[dbo].[EC_Matters] as Matters
  left join [DMZ-SQL01SVR].[eCase].[dbo].[EC_Clients] as Clients on Clients.[niClientID] = Matters.[niClientID]) as ECaseClient on cashdr.client collate database_default = ECaseClient.[sClientCode] collate database_default and ECaseClient.[sMatterCode] collate database_default = cashdr.matter collate database_default
WHERE AllData.case_id<>436013
END
GO
