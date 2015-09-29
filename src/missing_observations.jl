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
                Guide.ylabel("# assets"),
                Theme(bar_spacing=0.3mm));

draw(SVG("pics/missing_observations-1.svg", 16cm, 8cm), nObsHist)

nObsHistZoomed = plot(x=convert(Array, obsPerStock), Geom.histogram(bincount = 120),
                      Scale.x_continuous(format = :plain, minvalue=0,
                                         maxvalue=1000),
                      Scale.y_continuous(format = :plain,
                                         minvalue=0, maxvalue=6),
                      Guide.xlabel("# observations"),
                      Guide.ylabel("# assets"),
                      Theme(bar_spacing=1mm))

draw(SVG("pics/missing_observations-4.svg", 16cm, 8cm), nObsHistZoomed)


## get observations per date
##--------------------------

vals = asArr(pricesTm, Float64, NaN)
obsPerRow = sum(!isnan(vals), 2)
numDats = dat2num(idx(pricesTm))

nObsPerDate = plot(x=numDats, y=obsPerRow, Geom.line,
                   Scale.x_continuous(format = :plain),
                   Guide.xlabel("time"),
                   Guide.ylabel("# observations"));

draw(SVG("pics/missing_observations-2.svg", 16cm, 8cm), nObsPerDate)

## create table with ticker, first obs and nObs
##---------------------------------------------

firstObsPerStock = collapseDates(x ->
                                 idx(pricesTm)[find(!isna(x))[1]],
                                 eachcol(pricesTm))

obsTable = join(stack(firstObsPerStock, names(firstObsPerStock)),
               stack(obsPerStock, names(obsPerStock)),
               on = :variable, kind = :outer)

obsTable = names!(obsTable, [:Ticker, :FirstObs, :nObs])

## show stocks with maximum number of observations
##------------------------------------------------

indsMaxVal = [obsTable[:nObs] .== maximum(obsTable[:nObs])]

## display maximum observations
obsTable[indsMaxVal, [:Ticker, :nObs]]


## show stocks with less observation than threshold
##-------------------------------------------------

dats = dat2num(obsTable[:FirstObs])

pDatesVsFirstObs = plot(x=dats, y=convert(Array, obsTable[:nObs])[:],
                        Geom.point,
                        Scale.y_continuous(format = :plain),
                        Guide.xlabel("time of first observation"),
                        Guide.ylabel("# observations"));

draw(SVG("pics/missing_observations-3.svg", 16cm, 8cm), pDatesVsFirstObs)

## table with too few obs
##-----------------------

minNObs = [1000, 750, 500, 250]

## display how many companies less than given nObs
[minNObs Int[sum(obsTable[:nObs] .< nObs) for nObs in minNObs]]

minNObs = 500
[tooFewObs = obsTable[:nObs] .< minNObs]

## display table
obsTable[tooFewObs, :]
