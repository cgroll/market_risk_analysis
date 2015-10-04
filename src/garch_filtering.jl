## load required packages
##-----------------------

using TimeData
using Econometrics
loadPlotting()
using Gadfly

## load data and get log returns
pricesTm = readTimedata("financial_data/raw_data/SP500.csv")
nObs, nAss = size(pricesTm)
logRets = 100.*price2ret(log(pricesTm), log=true)

## function to extract first estimated sigma
function getFirstSigma(gFit::GARCH_1_1_Fit)
    ## get first non-missing sigma
    return dropna(gFit.sigmas.vals[1])[1]
end

## GARCH(1,1), normal innovations
##-------------------------------

## estimate GARCH(1,1) with normal innovations
@time begin
    nParams = 5
    estimatedParams = Array(Float64, nAss, nParams)
    estimatedSigmas = DataFrame()
    for ii=1:nAss
        display(ii)
        gFit = fit(GARCH_1_1{TDist}, logRets[ii])
        estimatedParams[ii, 1:4] = [gFit.model.μ, gFit.model.κ,
                                    gFit.model.α, gFit.model.β]
        estimatedParams[ii, 5] = getFirstSigma(gFit)
        
        estimatedSigmas[ii] = gFit.sigmas.vals[1]
    end
end

## put parameters in dataframe
estimatedParamsDf = DataFrame()
for ii=1:nParams
    estimatedParamsDf[ii] = estimatedParams[:, ii]
end

names!(estimatedParamsDf, [:μ, :κ, :α, :β, :σ0])

## put estimated sigmas in dataframe
estimatedSigmasDf = DataFrame()
for ii=1:nAss
    estimatedSigmasDf[ii] = estimatedSigmas[:, ii]
end

names!(estimatedSigmasDf, names(logRets)[1:nAss])

writetable("public_data/garch_norm_params.csv", estimatedParamsDf)
writetable("public_data/garch_norm_sigmas.csv", estimatedSigmasDf)

## GARCH(1,1), t innovations
##--------------------------

## estimate GARCH(1,1) with t innovations
@time begin
    nParams = 6
    estimatedParams = Array(Float64, nAss, nParams)
    estimatedSigmas = DataFrame()
    for ii=1:nAss
        display(ii)
        gFit = fit(GARCH_1_1{TDist}, logRets[ii])
        estimatedParams[ii, 1:4] = [gFit.model.μ, gFit.model.κ,
                                    gFit.model.α, gFit.model.β]
        estimatedParams[ii, 5] = getFirstSigma(gFit)
        estimatedParams[ii, 6] = dof(gFit.model.distr)
        
        estimatedSigmas[ii] = gFit.sigmas.vals[1]
    end
end

## put parameters in dataframe
estimatedParamsDf = DataFrame()
for ii=1:nParams
    estimatedParamsDf[ii] = estimatedParams[:, ii]
end

names!(estimatedParamsDf, [:μ, :κ, :α, :β, :σ0, :ν])

## put estimated sigmas in dataframe
estimatedSigmasDf = DataFrame()
for ii=1:nAss
    estimatedSigmasDf[ii] = estimatedSigmas[:, ii]
end

names!(estimatedSigmasDf, names(logRets)[1:nAss])

writetable("public_data/garch_t_params.csv", estimatedParamsDf)
writetable("public_data/garch_t_sigmas.csv", estimatedSigmasDf)

