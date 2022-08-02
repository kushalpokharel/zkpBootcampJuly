

## Return summation of every number below and up to including n
func calculate_sum(n : felt) -> (sum : felt): 
    if n==0:
        return(0)
    end
    let (prev_sum) = calculate_sum(n-1)
    return(prev_sum+n)
end
