using Distributions

"""Helper function for trapezoidal rule"""
function trapz(x, y)
    return sum((x[2:end] - x[1:(end - 1)]) .* (y[2:end] + y[1:(end - 1)])) * 0.5
end


function annual_loan_cost(p, r, n)
    #P is principle amount, r is rate, n is number of years
    #r = rate
    a = p * ( r * ((1+r)^n)  / ( (1+r)^n - 1 ) )
    #println(a, "place", "prin", p)
    return a #a is annual payments
end

function total_loan_cost(annual_cost, n) #can apply discount rate to this later
    #n is number of years of loan 
    print("total cost ran")
    return annual_cost*n 
end

"""
Run the model for a given action and SOW

Expected Annual Damages are computed using the trapezoidal rule
"""
function run_sim(a::Action, sow::SOW, p::ModelParams)

    # first, we calculate the cost of elevating the house
    construction_cost = elevation_cost(p.house, a.Δh_ft)

    fin = p.finance

    if fin.loan == 0  #if paying out of pocket
        upfront_cost = construction_cost
        annual_cost = 0
    elseif fin.loan==1   #if taking out a loan
        annual_cost = annual_loan_cost(construction_cost, fin.loan_rate, fin.loan_years)
        upfront_cost = annual_cost  #Have to pay for the first year of the loan
    
    else #if we decide to save up to elevate the house
        #we'll use loan_years to represent how long we're saving up for
        annual_cost = construction_cost/fin.loan_years 
        upfront_cost = annual_cost  #assume we start saving money in the first year

    end
  
        

    # we don't need to recalculate the steps of the trapezoidal integral for each year
    storm_surges_ft = range(
        quantile(sow.surge_dist, 0.0005); stop=quantile(sow.surge_dist, 0.9995), length=130
    )

    eads = map(p.years) do year
        #print(year)
        year_index = year - minimum(p.years)  #This is probably not an efficient way to do it since something similar is already calculated below 

        if year_index < fin.loan_years & (fin.loan > 1) #if we're still saving up
            action_this_year = 0#ustrip(u"ft", 0)  # then we're not elevating this year
            #annual_cost = annual_cost
            #println(fin.loan_rate)
            #println(annual_cost)
        else
            annual_cost = 0 #if not, set it to 0
            action_this_year = a.Δh_ft
        end
        # get the sea level for this year
        slr_ft = sow.slr(year)

        # Compute EAD using trapezoidal rule
        pdf_values = pdf.(sow.surge_dist, storm_surges_ft) # probability of each
        depth_ft_gauge = storm_surges_ft .+ slr_ft # flood at gauge
        depth_ft_house = depth_ft_gauge .- (p.house.height_above_gauge_ft + action_this_year) # flood @ house
        damages_frac = p.house.ddf.(depth_ft_house) ./ 100 # damage
        weighted_damages = damages_frac .* pdf_values # weighted damage
        # Trapezoidal integration of weighted damages
        ead = (trapz(storm_surges_ft, weighted_damages) * p.house.value_usd) + annual_cost
    end

    years_idx = p.years .- minimum(p.years)
    discount_fracs = (1 - sow.discount_rate) .^ years_idx
    ead_npv = sum(eads .* discount_fracs)
    return -(ead_npv + upfront_cost)
end
