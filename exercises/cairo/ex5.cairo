## I AM NOT DONE

## Implement a funcion that returns: 
## - 1 when magnitudes of inputs are equal
## - 0 otherwise
from starkware.cairo.common.math import sign
func abs_eq{range_check_ptr}(x : felt, y : felt) -> (bit : felt):
    if x==y:
        return(1)
    end
    if x*(-1)==y:
        return(1)
    end
    return (0)
end
