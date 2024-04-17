using Base: @kwdef
using Distributions
using StatsBase: mean


# @kwdef struct Finance#{T<:Real}
#     #loan stuff
#     loan::T  #Changed
#     loan_years::T #Changed 
#     loan_rate::T #Changed
# end





"""ModelParams contains all the variables that are constant across simulations"""
@kwdef struct ModelParams
    house::House
    years::Vector{Int}
    finance::Finance
end

"""A SOW contains all the variables that may vary from one simulation to the next"""
struct SOW{T<:Real}
    slr::Oddo17SLR # the parameters of sea-level rise
    surge_dist::Distributions.UnivariateDistribution # the distribution of storm surge
    discount_rate::T # the discount rate, as a percentage (e.g., 2% is 0.02)
end

"""
In this model, we only hvae one decision variable: how high to elevate the house.
"""
struct Action{T<:Real}
    Δh_ft::T
end
function Action(Δh::T) where {T<:Unitful.Length}
    Δh_ft = ustrip(u"ft", Δh)
    return Action(Δh_ft)
end
