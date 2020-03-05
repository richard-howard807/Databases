SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [dbo].[ufn_Coalesce_CapacityDetails_reference]
    (
     @case_id INT
    ,@capacity_code VARCHAR(8)
    )
    
/*	
'~ZCLAIM' returns Claimants
identical to ufn_Coalesce_CapacityDetails except cl_clname and marketing contact forename value is returned.
*/
    
RETURNS VARCHAR(255)
AS BEGIN
    DECLARE @string VARCHAR(255)
    SET @string = ''
    SELECT
        @string = @string + ISNULL(RTRIM(reference), '') + ', '
    FROM axxia01.dbo.capac capac WITH (NOLOCK)
    INNER JOIN axxia01.dbo.invol invol WITH (NOLOCK) ON  capac.capacity_code = invol.capacity_code
    WHERE
        capac.capacity_code = @capacity_code
        AND invol.case_id = @case_id
    
    IF LEN(@string) > 2 
        SET @string = LEFT(@string, LEN(@string) - 1)
    
    RETURN @string
   END





GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails_reference] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails_reference] TO [ssrs_dynamicsecurity]
GO
