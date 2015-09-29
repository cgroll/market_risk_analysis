## load required packages
##-----------------------

using TimeData
loadPlotting()
using Gadfly

## load raw data
##--------------

pricesTm = readTimedata("financial_data/raw_data/SP500.csv")
nObs, nAss = size(pricesTm)

## get observations per stock
##---------------------------

obsPerStock = collapseDates(x -> sum(!isna(x)), eachcol(pricesTm))

nObsHist = plot(x=convert(Array, obsPerStock), Geom.histogram(bincount = 20),
                Scale.x_continuous(format = :plain),
                Guide.xlabel("# observations"),
                Guide.ylabel("# assets"))

draw(SVG("pics/missing_observations-1.svg", 24cm, 12cm), nObsHist)
