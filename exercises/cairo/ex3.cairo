

## Perform and log output of simple arithmetic operations
func simple_math():
    
    ## adding 13 +  14
    let x = 13+14
    %{
        print(ids.x)
    %}
    ## multiplying 3 * 6
    let x = 3*6
    %{
        print(ids.x)
    %}
    ## dividing 6 by 2
    let x = 6*2
    %{
        print(ids.x)
    %}
    ## dividing 70 by 2
    let x = 70*2
    %{
        print(ids.x)
    %}
    ## dividing 7 by 2 
    let x = 7*2
    %{
        print(ids.x)
    %}
    return ()
end