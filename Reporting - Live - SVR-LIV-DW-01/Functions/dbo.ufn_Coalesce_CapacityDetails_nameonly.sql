SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--[dbo].[ufn_Coalesce_CapacityDetails_nameonly] '134538','~ZCLAIM'


CREATE FUNCTION [dbo].[ufn_Coalesce_CapacityDetails_nameonly]
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
        @string = @string + CASE WHEN CHARINDEX(LOWER(RTRIM(kdclicon.kc_fornam)), LOWER(RTRIM(cl_clname))) >=1
		THEN @string + RTRIM(cl_clname) + ', '
		ELSE LTRIM(ISNULL(RTRIM(kdclicon.kc_fornam) + ' ', '') + RTRIM(cl_clname)+ ', ') END
    FROM
        axxia01.dbo.capac capac WITH (NOLOCK)
    INNER JOIN axxia01.dbo.invol invol WITH (NOLOCK)
    ON  capac.capacity_code = invol.capacity_code
    INNER JOIN axxia01.dbo.caclient caclient WITH (NOLOCK)
    ON  invol.entity_code = caclient.cl_accode
    LEFT JOIN axxia01.dbo.kdclicon ON invol.entity_code = kdclicon.kc_client
    WHERE
        capac.capacity_code = @capacity_code
        AND invol.case_id = @case_id
    
    GROUP BY CASE WHEN CHARINDEX(LOWER(RTRIM(kdclicon.kc_fornam)), LOWER(RTRIM(cl_clname))) >=1
		THEN @string + RTRIM(cl_clname) + ', '
		ELSE LTRIM(ISNULL(RTRIM(kdclicon.kc_fornam) + ' ', '') + RTRIM(cl_clname) + ', ') END
    
    IF LEN(@string) > 2 
        SET @string = LEFT(@string, LEN(@string) - 1)
    
    RETURN @string
   END





GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails_nameonly] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails_nameonly] TO [ssrs_dynamicsecurity]
GO
