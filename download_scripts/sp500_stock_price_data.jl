using EconDatasets

include(joinpath(Pkg.dir(),
                 "EconDatasets/src/getDataset/getSP500.jl"))

dataPath = joinpath(Pkg.dir(),
                    "EconDatasets/data/SP500.csv")

newDataPath = "financial_data/raw_data/SP500.csv"

cp(dataPath, newDataPath)
