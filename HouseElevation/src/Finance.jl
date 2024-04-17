using Base: @kwdef
using DataFrames
using Interpolations
using Unitful

@kwdef struct Finance{T<:Real}
 
    #loan stuff
    loan::L  #Changed
    loan_years::loan_years #Changed 
    loan_rate::loan_rate #Changed
end

function annual_loan_cost(p, r, n)
    #P is principle amount, r is rate, n is number of years
    a = p * ( (r * ((1+r)^n) ) / ( (1+r)^n - 1 ) )
    return a #a is annual payments
end

function total_loan_cost(annual_cost, n) #can apply discount rate to this later
    #n is number of years of loan 
    print("total cost ran")
    return annual_cost*n 
end