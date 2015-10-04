using TimeData
using Econometrics
using Dates
loadPlotting()
using Gadfly

## load data and get log returns
pricesTm = readTimedata("financial_data/raw_data/SP500.csv")
nObs, nAss = size(pricesTm)


## get stocks with more observations than minimum number
##------------------------------------------------------

thres = 500

nObsPerStock = Int[length(dropna(pricesTm.vals[ii])) for ii=1:nAss]

validStocks = nObsPerStock .> 500

pickedStocks = pricesTm[:, validStocks]

## pick date range
##----------------

validDates = Date(1985,1,1):idx(pricesTm)[end]

pickedData = pickedStocks[validDates, :]

## write to disk
##--------------

writeTimedata("financial_data/processed_data/SP500.csv", pickedData)
