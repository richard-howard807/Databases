SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT * FROM [Converge].[vw_NonInsurerReserve](368213, '2012-06-01')
-- SELECT * FROM [Converge].[vw_NonInsurerReserve_live](368213)

CREATE FUNCTION [Converge].[vw_NonInsurerReserve_live] (
	  @CaseID int
)
RETURNS @rettab TABLE (case_id int, TotalReserveIncFees money, TotalReserveExcFees money)
AS
BEGIN
	INSERT INTO @rettab
	SELECT cashdr.case_id, 
		0 + ISNULL([VE00164].case_value,0)+ ISNULL([VE00172].case_value,0)+ ISNULL([VE00176].case_value,0)+ ISNULL([VE00180].case_value,0)
		+ ISNULL([VE00184].case_value,0)+ ISNULL([VE00188].case_value,0)+ ISNULL([VE00192].case_value,0)+ ISNULL([VE00196].case_value,0)
		+ ISNULL([VE00200].case_value,0)+ ISNULL([VE00204].case_value,0)+ ISNULL([VE00208].case_value,0)+ ISNULL([VE00212].case_value,0)
		+ ISNULL([VE00216].case_value,0)+ ISNULL([VE00220].case_value,0)+ ISNULL([VE00224].case_value,0)+ ISNULL([VE00228].case_value,0)
		+ ISNULL([VE00232].case_value,0)+ ISNULL([VE00236].case_value,0)+ ISNULL([VE00240].case_value,0)+ ISNULL([VE00244].case_value,0)
		+ ISNULL([VE00248].case_value,0)+ ISNULL([VE00252].case_value,0)+ ISNULL([VE00256].case_value,0)+ ISNULL([VE00260].case_value,0)
		+ ISNULL([VE00264].case_value,0)+ ISNULL([VE00268].case_value,0)+ ISNULL([VE00272].case_value,0)+ ISNULL([VE00280].case_value,0)
		+ ISNULL([VE00284].case_value,0)+ ISNULL([VE00289].case_value,0)+ ISNULL([VE00293].case_value,0)+ ISNULL([VE00297].case_value,0)
		+ ISNULL([VE00339].case_value,0)+ ISNULL([VE00343].case_value,0)+ ISNULL([VE00347].case_value,0)+ ISNULL([VE00351].case_value,0)
		+ ISNULL([VE00381].case_value,0)+ ISNULL([VE00385].case_value,0)+ ISNULL([VE00389].case_value,0)+ ISNULL([VE00393].case_value,0)
		+ ISNULL([VE00397].case_value,0)+ ISNULL([VE00401].case_value,0)+ ISNULL([VE00405].case_value,0)+ ISNULL([VE00409].case_value,0)
		+ ISNULL([VE00414].case_value,0)+ ISNULL([VE00415].case_value,0)+ ISNULL([VE00418].case_value,0)+ ISNULL([VE00422].case_value,0)
		+ ISNULL([VE00426].case_value,0) AS TotalReserveIncFees, 
		0 + ISNULL([VE00164].case_value,0)+ ISNULL([VE00172].case_value,0)+ ISNULL([VE00176].case_value,0)+ ISNULL([VE00180].case_value,0)
		+ ISNULL([VE00184].case_value,0)+ ISNULL([VE00188].case_value,0)+ ISNULL([VE00192].case_value,0)+ ISNULL([VE00196].case_value,0)
		+ ISNULL([VE00200].case_value,0)+ ISNULL([VE00204].case_value,0)+ ISNULL([VE00208].case_value,0)+ ISNULL([VE00212].case_value,0)
		+ ISNULL([VE00216].case_value,0)+ ISNULL([VE00220].case_value,0)+ ISNULL([VE00224].case_value,0)+ ISNULL([VE00228].case_value,0)
		+ ISNULL([VE00232].case_value,0)+ ISNULL([VE00236].case_value,0)+ ISNULL([VE00240].case_value,0)+ ISNULL([VE00244].case_value,0)
		+ ISNULL([VE00248].case_value,0)+ ISNULL([VE00252].case_value,0)+ ISNULL([VE00256].case_value,0)+ ISNULL([VE00260].case_value,0)
		+ ISNULL([VE00264].case_value,0)+ ISNULL([VE00268].case_value,0)+ ISNULL([VE00272].case_value,0)+ ISNULL([VE00280].case_value,0)
		+ ISNULL([VE00284].case_value,0)+ ISNULL([VE00289].case_value,0)+ ISNULL([VE00293].case_value,0)+ ISNULL([VE00297].case_value,0)
		+ ISNULL([VE00339].case_value,0)+ ISNULL([VE00343].case_value,0)+ ISNULL([VE00347].case_value,0)+ ISNULL([VE00351].case_value,0)
		+ ISNULL([VE00397].case_value,0)+ ISNULL([VE00401].case_value,0)+ ISNULL([VE00405].case_value,0)+ ISNULL([VE00409].case_value,0)
		+ ISNULL([VE00414].case_value,0)+ ISNULL([VE00415].case_value,0)+ ISNULL([VE00418].case_value,0)+ ISNULL([VE00422].case_value,0)
		+ ISNULL([VE00426].case_value,0) AS TotalReserveExcFees
	FROM axxia01.dbo.cashdr
	LEFT JOIN axxia01.dbo.casdet AS VE00164 ON axxia01.dbo.cashdr.case_id = VE00164.case_id AND  VE00164.case_detail_code = 'VE00164'
	LEFT JOIN axxia01.dbo.casdet AS VE00172 ON axxia01.dbo.cashdr.case_id = VE00172.case_id AND  VE00172.case_detail_code = 'VE00172'
	LEFT JOIN axxia01.dbo.casdet AS VE00176 ON axxia01.dbo.cashdr.case_id = VE00176.case_id AND  VE00176.case_detail_code = 'VE00176'
	LEFT JOIN axxia01.dbo.casdet AS VE00180 ON axxia01.dbo.cashdr.case_id = VE00180.case_id AND  VE00180.case_detail_code = 'VE00180'
	LEFT JOIN axxia01.dbo.casdet AS VE00184 ON axxia01.dbo.cashdr.case_id = VE00184.case_id AND  VE00184.case_detail_code = 'VE00184'
	LEFT JOIN axxia01.dbo.casdet AS VE00188 ON axxia01.dbo.cashdr.case_id = VE00188.case_id AND  VE00188.case_detail_code = 'VE00188'
	LEFT JOIN axxia01.dbo.casdet AS VE00192 ON axxia01.dbo.cashdr.case_id = VE00192.case_id AND  VE00192.case_detail_code = 'VE00192'
	LEFT JOIN axxia01.dbo.casdet AS VE00196 ON axxia01.dbo.cashdr.case_id = VE00196.case_id AND  VE00196.case_detail_code = 'VE00196'
	LEFT JOIN axxia01.dbo.casdet AS VE00200 ON axxia01.dbo.cashdr.case_id = VE00200.case_id AND  VE00200.case_detail_code = 'VE00200'
	LEFT JOIN axxia01.dbo.casdet AS VE00204 ON axxia01.dbo.cashdr.case_id = VE00204.case_id AND  VE00204.case_detail_code = 'VE00204'
	LEFT JOIN axxia01.dbo.casdet AS VE00208 ON axxia01.dbo.cashdr.case_id = VE00208.case_id AND  VE00208.case_detail_code = 'VE00208'
	LEFT JOIN axxia01.dbo.casdet AS VE00212 ON axxia01.dbo.cashdr.case_id = VE00212.case_id AND  VE00212.case_detail_code = 'VE00212'
	LEFT JOIN axxia01.dbo.casdet AS VE00216 ON axxia01.dbo.cashdr.case_id = VE00216.case_id AND  VE00216.case_detail_code = 'VE00216'
	LEFT JOIN axxia01.dbo.casdet AS VE00220 ON axxia01.dbo.cashdr.case_id = VE00220.case_id AND  VE00220.case_detail_code = 'VE00220'
	LEFT JOIN axxia01.dbo.casdet AS VE00224 ON axxia01.dbo.cashdr.case_id = VE00224.case_id AND  VE00224.case_detail_code = 'VE00224'
	LEFT JOIN axxia01.dbo.casdet AS VE00228 ON axxia01.dbo.cashdr.case_id = VE00228.case_id AND  VE00228.case_detail_code = 'VE00228'
	LEFT JOIN axxia01.dbo.casdet AS VE00232 ON axxia01.dbo.cashdr.case_id = VE00232.case_id AND  VE00232.case_detail_code = 'VE00232'
	LEFT JOIN axxia01.dbo.casdet AS VE00236 ON axxia01.dbo.cashdr.case_id = VE00236.case_id AND  VE00236.case_detail_code = 'VE00236'
	LEFT JOIN axxia01.dbo.casdet AS VE00240 ON axxia01.dbo.cashdr.case_id = VE00240.case_id AND  VE00240.case_detail_code = 'VE00240'
	LEFT JOIN axxia01.dbo.casdet AS VE00244 ON axxia01.dbo.cashdr.case_id = VE00244.case_id AND  VE00244.case_detail_code = 'VE00244'
	LEFT JOIN axxia01.dbo.casdet AS VE00248 ON axxia01.dbo.cashdr.case_id = VE00248.case_id AND  VE00248.case_detail_code = 'VE00248'
	LEFT JOIN axxia01.dbo.casdet AS VE00252 ON axxia01.dbo.cashdr.case_id = VE00252.case_id AND  VE00252.case_detail_code = 'VE00252'
	LEFT JOIN axxia01.dbo.casdet AS VE00256 ON axxia01.dbo.cashdr.case_id = VE00256.case_id AND  VE00256.case_detail_code = 'VE00256'
	LEFT JOIN axxia01.dbo.casdet AS VE00260 ON axxia01.dbo.cashdr.case_id = VE00260.case_id AND  VE00260.case_detail_code = 'VE00260'
	LEFT JOIN axxia01.dbo.casdet AS VE00264 ON axxia01.dbo.cashdr.case_id = VE00264.case_id AND  VE00264.case_detail_code = 'VE00264'
	LEFT JOIN axxia01.dbo.casdet AS VE00268 ON axxia01.dbo.cashdr.case_id = VE00268.case_id AND  VE00268.case_detail_code = 'VE00268'
	LEFT JOIN axxia01.dbo.casdet AS VE00272 ON axxia01.dbo.cashdr.case_id = VE00272.case_id AND  VE00272.case_detail_code = 'VE00272'
	LEFT JOIN axxia01.dbo.casdet AS VE00280 ON axxia01.dbo.cashdr.case_id = VE00280.case_id AND  VE00280.case_detail_code = 'VE00280'
	LEFT JOIN axxia01.dbo.casdet AS VE00284 ON axxia01.dbo.cashdr.case_id = VE00284.case_id AND  VE00284.case_detail_code = 'VE00284'
	LEFT JOIN axxia01.dbo.casdet AS VE00289 ON axxia01.dbo.cashdr.case_id = VE00289.case_id AND  VE00289.case_detail_code = 'VE00289'
	LEFT JOIN axxia01.dbo.casdet AS VE00293 ON axxia01.dbo.cashdr.case_id = VE00293.case_id AND  VE00293.case_detail_code = 'VE00293'
	LEFT JOIN axxia01.dbo.casdet AS VE00297 ON axxia01.dbo.cashdr.case_id = VE00297.case_id AND  VE00297.case_detail_code = 'VE00297'
	LEFT JOIN axxia01.dbo.casdet AS VE00339 ON axxia01.dbo.cashdr.case_id = VE00339.case_id AND  VE00339.case_detail_code = 'VE00339'
	LEFT JOIN axxia01.dbo.casdet AS VE00343 ON axxia01.dbo.cashdr.case_id = VE00343.case_id AND  VE00343.case_detail_code = 'VE00343'
	LEFT JOIN axxia01.dbo.casdet AS VE00347 ON axxia01.dbo.cashdr.case_id = VE00347.case_id AND  VE00347.case_detail_code = 'VE00347'
	LEFT JOIN axxia01.dbo.casdet AS VE00351 ON axxia01.dbo.cashdr.case_id = VE00351.case_id AND  VE00351.case_detail_code = 'VE00351'
	LEFT JOIN axxia01.dbo.casdet AS VE00381 ON axxia01.dbo.cashdr.case_id = VE00381.case_id AND  VE00381.case_detail_code = 'VE00381'
	LEFT JOIN axxia01.dbo.casdet AS VE00385 ON axxia01.dbo.cashdr.case_id = VE00385.case_id AND  VE00385.case_detail_code = 'VE00385'
	LEFT JOIN axxia01.dbo.casdet AS VE00389 ON axxia01.dbo.cashdr.case_id = VE00389.case_id AND  VE00389.case_detail_code = 'VE00389'
	LEFT JOIN axxia01.dbo.casdet AS VE00393 ON axxia01.dbo.cashdr.case_id = VE00393.case_id AND  VE00393.case_detail_code = 'VE00393'
	LEFT JOIN axxia01.dbo.casdet AS VE00397 ON axxia01.dbo.cashdr.case_id = VE00397.case_id AND  VE00397.case_detail_code = 'VE00397'
	LEFT JOIN axxia01.dbo.casdet AS VE00401 ON axxia01.dbo.cashdr.case_id = VE00401.case_id AND  VE00401.case_detail_code = 'VE00401'
	LEFT JOIN axxia01.dbo.casdet AS VE00405 ON axxia01.dbo.cashdr.case_id = VE00405.case_id AND  VE00405.case_detail_code = 'VE00405'
	LEFT JOIN axxia01.dbo.casdet AS VE00409 ON axxia01.dbo.cashdr.case_id = VE00409.case_id AND  VE00409.case_detail_code = 'VE00409'
	LEFT JOIN axxia01.dbo.casdet AS VE00414 ON axxia01.dbo.cashdr.case_id = VE00414.case_id AND  VE00414.case_detail_code = 'VE00414'
	LEFT JOIN axxia01.dbo.casdet AS VE00415 ON axxia01.dbo.cashdr.case_id = VE00415.case_id AND  VE00415.case_detail_code = 'VE00415'
	LEFT JOIN axxia01.dbo.casdet AS VE00418 ON axxia01.dbo.cashdr.case_id = VE00418.case_id AND  VE00418.case_detail_code = 'VE00418'
	LEFT JOIN axxia01.dbo.casdet AS VE00422 ON axxia01.dbo.cashdr.case_id = VE00422.case_id AND  VE00422.case_detail_code = 'VE00422'
	LEFT JOIN axxia01.dbo.casdet AS VE00426 ON axxia01.dbo.cashdr.case_id = VE00426.case_id AND  VE00426.case_detail_code = 'VE00426'
	WHERE cashdr.case_id = @CaseID

	RETURN
END
GO
