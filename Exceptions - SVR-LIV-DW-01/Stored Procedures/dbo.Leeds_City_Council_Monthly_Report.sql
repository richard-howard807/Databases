SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2019-02-15
-- Description:	Leeds_City_Council_Monthly_Report
-- =============================================
CREATE PROCEDURE [dbo].[Leeds_City_Council_Monthly_Report]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT FwactMafile.maclin,
       FwactMafile.mamatn,
       ISNULL(webdbMAFILE.mate15, '') 'Debtor Name',
       ISNULL(webdbCDFILE.cdte16, '') 'Invoice Number (Client Ref)',
       ISNULL(webdbUDFILE.udte02, '') 'Debt Type',
       ISNULL(webdbDMDFILE.mdtotl, 0) 'Debt Amount',
       ISNULL(SUM(webdbDHIFILE.[Fixed Costs]),0) [Fixed Costs],
       ISNULL(SUM(webdbDHIFILE.Disbursements) ,0) Disbursements,
       ISNULL(SUM(webdbDHIFILE.Interest_before),0)  Interest_Before,
	   ISNULL(SUM(webdbDHIFILE.Interest_after),0)  Interest_After,
	   ISNULL(SUM(webdbDHIFILE.Interest_total),0)  Interest_Total,
       ISNULL(SUM(webdbDHIFILE.Payments),0)  Payments,
       ISNULL(SUM(webdbDHIFILE.[Fixed Costs (Last Month)]),0)  [Fixed Costs (Last Month)],
       ISNULL(SUM(webdbDHIFILE.[Disbursements (Last Month)]),0) [Disbursements (Last Month)],
       RTRIM(ISNULL(CAST(webdbMDFILE.mdreso AS VARCHAR(8000)), '')) 'Current Position'
FROM red_dw.dbo.ds_sh_fwa_mafile FwactMafile
    LEFT JOIN red_dw.dbo.ds_sh_fw_web_mdfile AS webdbMDFILE ON FwactMafile.maclin = webdbMDFILE.mdclin  AND FwactMafile.mamatn = webdbMDFILE.mdmatn --AND webdbMDFILE.dss_current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_fw_web_mafile AS webdbMAFILE ON FwactMafile.maclin = webdbMAFILE.maclin AND FwactMafile.mamatn = webdbMAFILE.mamatn AND webdbMAFILE.dss_current_flag = 'Y'
    LEFT JOIN red_dw.dbo.ds_sh_fw_web_dmdfile AS webdbDMDFILE ON FwactMafile.maclin = webdbDMDFILE.mdclin AND FwactMafile.mamatn = webdbDMDFILE.mdmatn AND webdbDMDFILE.dss_current_flag = 'Y'
    LEFT JOIN
    (
      SELECT hiclin,
               himatn,
               CASE
                   WHEN webdbDHIFILE.hitype = 3 THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Fixed Costs',
               CASE
                   WHEN webdbDHIFILE.hitype IN ( 4, 5 ) THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Disbursements',
               CASE
                   WHEN webdbDHIFILE.hitype = 2 AND (webdbDHIFILE.hidate <= Judgment.Judgment_Date OR Judgment.Judgment_Date IS NULL) THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Interest_before',
			   CASE
                   WHEN webdbDHIFILE.hitype = 2 AND webdbDHIFILE.hidate > Judgment.Judgment_Date THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Interest_after',
			    CASE
                   WHEN webdbDHIFILE.hitype = 2  THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Interest_total',
               CASE
                   WHEN ISNULL(webdbDHIFILE.hiamnt, 0) < 0
                        AND webdbDHIFILE.hidesc NOT LIKE '%Recalculation of Debt for new action - %' THEN
                       ISNULL(ABS(webdbDHIFILE.hiamnt), 0)
                   ELSE
                       0
               END 'Payments',
               CASE
                   WHEN webdbDHIFILE.hitype = 3
                        AND webdbDHIFILE.hidate > CAST(YEAR(DATEADD(MONTH, -1, GETDATE())) AS NVARCHAR(4))
                                                  + RIGHT('00'
                                                          + CAST(MONTH(DATEADD(MONTH, -1, GETDATE())) AS NVARCHAR(2)), 2)
                                                  + '01 00:00:00'
                        AND webdbDHIFILE.hidate <= CAST(YEAR(DATEADD(MONTH, 0, GETDATE())) AS NVARCHAR(4))
                                                   + RIGHT('00'
                                                           + CAST(MONTH(DATEADD(MONTH, 0, GETDATE())) AS NVARCHAR(2)), 2)
                                                   + '01 00:00:00' THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Fixed Costs (Last Month)',
               CASE
                   WHEN webdbDHIFILE.hitype IN ( 4, 5 )
                        AND webdbDHIFILE.hidate > CAST(YEAR(DATEADD(MONTH, -1, GETDATE())) AS NVARCHAR(4))
                                                  + RIGHT('00'
                                                          + CAST(MONTH(DATEADD(MONTH, -1, GETDATE())) AS NVARCHAR(2)), 2)
                                                  + '01 00:00:00'
                        AND webdbDHIFILE.hidate <= CAST(YEAR(DATEADD(MONTH, 0, GETDATE())) AS NVARCHAR(4))
                                                   + RIGHT('00'
                                                           + CAST(MONTH(DATEADD(MONTH, 0, GETDATE())) AS NVARCHAR(2)), 2)
                                                   + '01 00:00:00' THEN
                       ISNULL(webdbDHIFILE.hiamnt, 0)
                   ELSE
                       0
               END 'Disbursements (Last Month)'
			   
        FROM red_dw.dbo.ds_sh_fw_web_dhifile AS webdbDHIFILE
		LEFT JOIN (SELECT hiclin client,himatn matter ,MAX(hidate) Judgment_Date from red_dw.dbo.ds_sh_fw_web_dhifile Judgment
		WHERE Judgment.hidesc LIKE 'Entered Judgment%'  GROUP BY hiclin,himatn) Judgment ON 
		Judgment.client = webdbDHIFILE.hiclin AND Judgment.matter = webdbDHIFILE.himatn
    ) AS webdbDHIFILE ON FwactMafile.maclin = webdbDHIFILE.hiclin AND FwactMafile.mamatn = webdbDHIFILE.himatn
    LEFT JOIN red_dw.dbo.ds_sh_fw_web_cdfile AS webdbCDFILE ON FwactMafile.maclin = webdbCDFILE.cdclin AND FwactMafile.mamatn = webdbCDFILE.cdmatn AND  webdbCDFILE.dss_current_flag = 'Y'
    INNER JOIN red_dw.dbo.ds_sh_fw_web_udfile AS webdbUDFILE ON FwactMafile.maclin = webdbUDFILE.udclin AND FwactMafile.mamatn = webdbUDFILE.udmatn AND  webdbUDFILE.dss_current_flag = 'Y'
    INNER JOIN red_dw.dbo.ds_sh_fw_web_uffile AS webdbUFFILE WITH (NOLOCK) ON FwactMafile.maclin = webdbUFFILE.ufclin AND FwactMafile.mamatn = webdbUFFILE.ufmatn AND  webdbUFFILE.dss_current_flag = 'Y'
WHERE FwactMafile.maclin = 3600
      AND FwactMafile.mastat IN ( 1, 2 )
      AND FwactMafile.mamatn NOT IN ( 164, 597, 705, 706, 907, 908 )
      AND webdbUFFILE.uflate = 41
      AND webdbUDFILE.udte25 NOT LIKE 'closed'
	  AND FwactMafile.dss_current_flag = 'Y'
	  --AND hiclin = '3600' AND himatn = '3748' 
GROUP BY FwactMafile.maclin,
         FwactMafile.mamatn,
         webdbMAFILE.mate15,
         webdbCDFILE.cdte16,
         webdbDMDFILE.mdtotl,
         RTRIM(ISNULL(CAST(webdbMDFILE.mdreso AS VARCHAR(8000)), '')),
         webdbUDFILE.udte02
ORDER BY FwactMafile.maclin,
         FwactMafile.mamatn;



END
GO
