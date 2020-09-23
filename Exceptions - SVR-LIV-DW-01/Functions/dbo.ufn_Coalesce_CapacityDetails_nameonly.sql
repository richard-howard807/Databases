SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--[dbo].[ufn_Coalesce_CapacityDetails_nameonly] '134538','~ZCLAIM'


CREATE function [dbo].[ufn_Coalesce_CapacityDetails_nameonly]
    (
     @case_id int
    ,@capacity_code varchar(8)
    )
    
/*	
'~ZCLAIM' returns Claimants
identical to ufn_Coalesce_CapacityDetails except cl_clname and marketing contact forename value is returned.
*/
 
  
    
returns varchar(255)
as BEGIN


    declare @string varchar(255)
    set @string = ''
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
    
    if len(@string) > 2 
        set @string = left(@string, len(@string) - 1)
    
    RETURN @string
   end





GO
