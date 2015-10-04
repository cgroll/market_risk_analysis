using TimeData
using Econometrics
using EconDatasets
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

tickChanges = [Date(1997, 6, 24), Date(2001, 1, 29)]
pZeroRetFrequOverTime = plot(layer(x=dat2num(idx(logRets)),
                                   y=zeroRetFrequOverTime,
                                   Geom.line, order=1),
                             layer(Geom.vline(color="red"),
                                   xintercept=[dat2num(tickChanges)],
                                   order=2),
                             Scale.x_continuous(format = :plain),
                             Guide.xlabel("time"),
                             Guide.ylabel("zero return frequency"))

draw(SVG("pics/zero_returns-4.svg", 16cm, 8cm), pZeroRetFrequOverTime)

## download SP500 index
##---------------------

indexData = readTimedata("financial_data/raw_data/index_data.csv")

sp500Index = convert(Timematr, narm(indexData[:_GSPC]))
sp500LogRets = 100*price2ret(log(sp500Index))

## fit normal and t GARCH to extract volatility series
gFit = fit(GARCH_1_1{TDist}, sp500LogRets)
## gFitNorm = fit(GARCH_1_1{Normal}, sp500LogRets)


## relative number of zeros in individual sections
##------------------------------------------------

## define regimes
firstRegime = idx(logRets)[1]:(tickChanges[1] - Dates.Day(1))
secondRegime = tickChanges[1]:(tickChanges[2] - Dates.Day(1))
thirdRegime = tickChanges[2]:idx(logRets)[end]

regimes = Any[firstRegime, secondRegime, thirdRegime]

## display overall zero return frequency per regime
for regime in regimes
    regimeRets = logRets[regime, :]
    longFormat = stack(regimeRets.vals, names(regimeRets.vals))
    longFormatRets = dropna(longFormat[:value])
    regimeZeroFreq = sum(longFormatRets .== 0)./length(longFormatRets)
    println("\nThe overall zero return frequency of the regime is:\n")
    display(regimeZeroFreq)
end

## zero return frequency vs sigma series
##--------------------------------------

## build Timenum with zero return frequency
zeroRetFrequTn = Timenum(DataFrame(zeroRetFreq = zeroRetFrequOverTime),
                         idx(logRets))

## build table with sigmas and zero return frequency
sigmaFreqTable = sort(join(convert(DataFrame, zeroRetFrequTn),
                      convert(DataFrame, gFit.sigmas),
                      on = :idx, kind = :left),
                      cols = [:idx])

sigmaFreqData = Timenum(sigmaFreqTable[2:3], sigmaFreqTable[1])

sigmaFreqPlots = Array(Any, 3)
regimeCorrs = Array(Float64, 3)

nPreviousPics = 4
counter = 1
for regime in regimes
    regimeData = sigmaFreqData[regime, :]

    currZeroRetFreq = regimeData[1]
    currSigmas = regimeData[2]

    currZeroRetFreqArr = asArr(currZeroRetFreq, Float64, NaN)[:]
    currSigmaArr = asArr(currSigmas, Float64, NaN)[:]

    currCor = cor(convert(Timematr, narm(regimeData)))
    regimeCorrs[counter] = currCor[1, 2]

    ## standardize time series for plotting
    currSigmaArrNoNaN = currSigmaArr[!isnan(currSigmaArr)]
    stdSigmas = (currSigmaArr -
    mean(currSigmaArrNoNaN))/std(currSigmaArrNoNaN)

    stdZeroRets = (currZeroRetFreqArr - mean(currZeroRetFreqArr))/std(currZeroRetFreqArr)
    p = plot(layer(x=dat2num(idx(regimeData)),
                   y=stdSigmas,
                   Geom.line),
             layer(x=dat2num(idx(regimeData)),
                   y=-stdZeroRets,
                   Geom.smooth(method=:loess,smoothing=0.1),
                   Theme(default_color=color("red")),
                   order=1),
             Scale.y_continuous(minvalue=-6, maxvalue=6),
             Guide.xlabel("time"),
             Guide.ylabel("volatility"))

    picNum = nPreviousPics + counter
    draw(SVG("pics/zero_returns-$picNum.svg", 16cm, 8cm),
         p)
    sigmaFreqPlots[counter] = p
    counter += 1
end

sigmaFreqPlots[1]
sigmaFreqPlots[2]
sigmaFreqPlots[3]

## display correlations
println("\nThe correlations of the regimes are:\n")
display(regimeCorrs)
println("\n")
