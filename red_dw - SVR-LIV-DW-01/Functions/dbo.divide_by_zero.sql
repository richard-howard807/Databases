SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[divide_by_zero]( @Numerator decimal(10,2), @divisor decimal(10,2))
   returns decimal(10,2)
begin
-- Code used to remove error occuring whilst dividing by 0
   declare @p_product    decimal(10,2);

   select @p_product = -1;

   if ( @divisor is not null and @divisor <> 0 and @Numerator is not null )
      select @p_product = @Numerator / @divisor;

   return(@p_product)
end
GO
GRANT ALTER ON  [dbo].[divide_by_zero] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
GRANT EXECUTE ON  [dbo].[divide_by_zero] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
