SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PlotCompletionReport]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN 

SELECT
master_client_code + '-' + master_matter_number AS [Client & Matter Reference]
,name AS [Fee Earner Name]
,txtPlotNo AS [Plot Number]
,COALESCE(david_wilson_homes_limited_developments
,barratt_manchester_developments
,bardsley_development
,thomas_jones_sons_limited_development
,persimmon_homes_limited_development
,manchester_ship_canal_developments_advent_limited
,greenfields_place_development_company_limited_developments) AS [Development Name]
,CASE WHEN cboFundRec ='Y' THEN 'Yes' WHEN cboFundRec='N' THEN 'No' ELSE cboFundRec END AS [Funds received]
,curProcVal AS [Proceeds of Sale amount]
,curLegalFeePS AS [Legal Fee]
,curTTFee AS [TT Fee]
,curAdminFeePS AS [Admin Fee]
,curOtherDisbPS AS [Other Disbursements]
,Company  AS [Addressee – Invoice 1]
,curDocFeePS AS [Document Fee]
,txtPurchaser1Fullname AS [Document Fee Paid by]
,curPartExFee AS [Part Exchange Legal Fee]
,curPartExDisb AS [Part Exchange Other Disbursement]
,NULL AS [Part Exchange File Reference]
,mtxtAddressPartEx   AS [Part Exchange Property Address]
,NULL AS [Builder Account Details]
,txtSortCodePS AS [Sort Code]
,txtAccNumberPS AS [Account Number]
,txtAccRefPS AS [Account Reference]
,CASE WHEN cboFinInstruct ='Y' THEN 'Yes' WHEN cboFinInstruct='N' THEN 'No' ELSE cboFinInstruct END  AS [Finance Instructed]
,red_dw.dbo.datetimelocal(dteCompDate) AS [Completion Date]
,dim_detail_plot_details.exchange_date AS [Exchange Date]
--,cboHasRetRec AS [Has retention undertaking been received?”]
--,cboRecCTD AS [Have we received CTD – Confirmation to Developer]
--,cboRecWarrNot AS [Have we received Warranty cover note]
--,cboH2BRec AS [Help to Buy Undertaking received]
--,cboHoldLease AS [Holding signed original lease or transfer on file]
--,cboCompSign AS [Is Exchange signed off]



FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_plot_details
 ON dim_detail_plot_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_plot_details.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN MS_Prod.dbo.udPlotSalesFileOpeningTF
 ON ms_fileid=udPlotSalesFileOpeningTF.fileID
LEFT OUTER JOIN MS_Prod.dbo.udPlotSalesPreExc
 ON ms_fileid=udPlotSalesPreExc.fileID
LEFT OUTER JOIN ms_prod.dbo.udPlotSalesExchange
 ON ms_fileid=udPlotSalesExchange.fileID
LEFT OUTER JOIN 
(
SELECT  fileID,STRING_AGG(contName,',') AS Company
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='BUILDCOMPANY'
AND assocActive=1
GROUP BY fileID
) AS Assoc
 ON ms_fileid=Assoc.fileID
WHERE  CONVERT(DATE,red_dw.dbo.datetimelocal(dteCompDate),103) BETWEEN @StartDate AND @EndDate
AND cboFundRec ='Y'
AND cboFinInstruct='N'

END
GO
