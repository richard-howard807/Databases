SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LeedsDeedsNonPunch]
(
@Search AS NVARCHAR(MAX)
) 
AS 

IF @Search='All'

BEGIN

SELECT cdcust AS [DeedNo],
cdtitl AS Title,
       cdforn AS Forename,
       cdsurn AS Surname,
       cdcad1 AS Address1,
       cdcad2 AS Address2,
       cdcad3 AS Address3,
       cdcad4 AS Address4,
       cdcpco AS Postcode,
       cdpad1 AS DeedAddress1,
       cdpad2 AS DeedAddress2,
       cdpad3 AS DeedAddress3,
       cdpad4 AS DeedAddress4,
       cdppco AS DeedPostcode,
       cdfeee AS FeeEarner,
       cdstod AS DeedStoredDate,
       cdclma AS ClientMatter,
       cdcomm AS Comments,
       cddesc AS [Description],
       cdreqd AS RequestedBy,
       csdesc AS CurrentStatus

FROM [SVR-LIV-3PTY-01].fw_deeds.dbo.cdfile,
     [SVR-LIV-3PTY-01].fw_deeds.dbo.csfile
WHERE cdstat = csidno
 
 END 
ELSE 

BEGIN

SELECT cdcust AS [DeedNo],
cdtitl AS Title,
       cdforn AS Forename,
       cdsurn AS Surname,
       cdcad1 AS Address1,
       cdcad2 AS Address2,
       cdcad3 AS Address3,
       cdcad4 AS Address4,
       cdcpco AS Postcode,
       cdpad1 AS DeedAddress1,
       cdpad2 AS DeedAddress2,
       cdpad3 AS DeedAddress3,
       cdpad4 AS DeedAddress4,
       cdppco AS DeedPostcode,
       cdfeee AS FeeEarner,
       cdstod AS DeedStoredDate,
       cdclma AS ClientMatter,
       cdcomm AS Comments,
       cddesc AS [Description],
       cdreqd AS RequestedBy,
       csdesc AS CurrentStatus

FROM [SVR-LIV-3PTY-01].fw_deeds.dbo.cdfile,
     [SVR-LIV-3PTY-01].fw_deeds.dbo.csfile
WHERE cdstat = csidno
 AND cdsurn LIKE '%' + @Search + '%'
 END 
GO
