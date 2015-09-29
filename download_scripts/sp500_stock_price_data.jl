using EconDatasets

## specify date range
dates = Date(1960,1,1):Date(2015,9,25)

## allow parallelization
procIds = addprocs(3)
    
@everywhere using DataFrames
@everywhere using TimeData
@everywhere using EconDatasets
    
## load WikiPedia stock ticker symbols
constituents = readcsv("financial_data/raw_data/SP500TickerSymbols.csv")
    
tickerSymb = ASCIIString[ticker for ticker in constituents]

## measure time
t0 = time()

@time vals = readYahooAdjClose(dates, tickerSymb, :d)

t1 = time()
elapsedTime = t1-t0
mins, secs = divrem(elapsedTime, 60)

valsTn = convert(Timenum, vals)
pathToStore = "financial_data/raw_data/SP500.csv"
writeTimedata(pathToStore, valsTn)

println("elapsed time: ", int(mins), " minutes, ", ceil(secs), " seconds")

rmprocs(procIds)
