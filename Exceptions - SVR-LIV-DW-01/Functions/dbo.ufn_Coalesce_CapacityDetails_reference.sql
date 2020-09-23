SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE function [dbo].[ufn_Coalesce_CapacityDetails_reference]
    (
     @case_id int
    ,@capacity_code varchar(8)
    )
    
/*	
'~ZCLAIM' returns Claimants
identical to ufn_Coalesce_CapacityDetails except cl_clname and marketing contact forename value is returned.
*/
    
returns varchar(255)
as begin
    declare @string varchar(255)
    set @string = ''
    SELECT
        @string = @string + ISNULL(RTRIM(reference), '') + ', '
    FROM axxia01.dbo.capac capac WITH (NOLOCK)
    INNER JOIN axxia01.dbo.invol invol WITH (NOLOCK) ON  capac.capacity_code = invol.capacity_code
    WHERE
        capac.capacity_code = @capacity_code
        AND invol.case_id = @case_id
    
    if len(@string) > 2 
        set @string = left(@string, len(@string) - 1)
    
    return @string
   end




GO
