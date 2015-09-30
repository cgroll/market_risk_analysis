using TimeData
using Econometrics
using Gadfly
loadPlotting()

## load raw data
##--------------

pricesTm = readTimedata("financial_data/raw_data/SP500.csv")
nObs, nAss = size(pricesTm)

logRets = price2ret(log(pricesTm), log=true)
logRetsFloat = asArr(logRets, Float64, NaN)

## display overall number of returns and zero frequency
nPossibleRets = (nObs-1)*nAss
nRetObs = sum(!isnan(logRetsFloat))
nanFrequ = 1 - nRetObs / nPossibleRets
zeroFreq = sum(logRetsFloat .== 0) / nRetObs


## plotting absolute number of zero returns per stock
##---------------------------------------------------

pZeroRets = plot(x=sum(logRetsFloat .== 0, 1)[:], Geom.histogram(bincount = 40),
                 Scale.x_continuous(format = :plain),
                 Guide.xlabel("# zero returns"),
                 Guide.ylabel("# assets"),
                 Theme(bar_spacing=0.3mm));
                
draw(SVG("pics/zero_returns-1.svg", 16cm, 8cm), pZeroRets)

## plotting relative number of zero returns per stock
##---------------------------------------------------

nRetsPerStock = sum(!isnan(logRetsFloat), 1)
relNumbZeroRets = sum(logRetsFloat .== 0, 1)./nRetsPerStock
    
pRelZeroRets = plot(x=relNumbZeroRets[:], Geom.histogram(bincount = 40),
                 Scale.x_continuous(format = :plain),
                 Guide.xlabel("# zero returns"),
                 Guide.ylabel("# assets"),
                 Theme(bar_spacing=0.3mm));
                
draw(SVG("pics/zero_returns-2.svg", 16cm, 8cm), pRelZeroRets)

## relative number of zero returns vs first observation
##-----------------------------------------------------

firstObsPerStockDf = collapseDates(x ->
                                 idx(logRets)[find(!isna(x))[1]],
                                 eachcol(logRets))

firstObsPerStock = dat2num(convert(Array, firstObsPerStockDf)[:])

pRelZeroRetsVsFirstObs = plot(x=firstObsPerStock, y=relNumbZeroRets, Geom.point,
                              Scale.x_continuous(format = :plain),
                              Guide.xlabel("time of first observation"),
                              Guide.ylabel("zero return frequency"))

draw(SVG("pics/zero_returns-3.svg", 16cm, 8cm), pRelZeroRetsVsFirstObs)

## relative number of zero returns over time
##------------------------------------------

nObsPerDate = sum(!isnan(logRetsFloat), 2)[:]
zeroRetFrequOverTime = sum(logRetsFloat .== 0, 2)[:] ./ nObsPerDate

pZeroRetFrequOverTime = plot(x=dat2num(idx(logRets)),
                             y=zeroRetFrequOverTime,
                             Geom.line,
                             Scale.x_continuous(format = :plain),
                             Guide.xlabel("time"),
                             Guide.ylabel("zero return frequency"))

