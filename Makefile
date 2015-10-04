
# gnu makefile for cfm

PROJ_DIR := .
PICS_DIR := pics
PRIV_DATA_DIR := financial_data
DATA_DIR := data
DATA_SRC := data_src
PICS_SRC := src

############################################################
############## SPECIFY MAIN DATA FOR EACH PROCESSING SCRIPT:
############################################################

SP500_RAW_DATA := raw_data/SP500TickerSymbols.csv raw_data/SP500.csv raw_data/SP500IndustryAffil.csv raw_data/index_data.csv
SP500_PROCESSED_DATA := processed_data/SP500.csv
GARCH_DATA := public_data/garch_norm_params.csv

PRIV_DATA_NAMES := $(SP500_RAW_DATA) $(SP500_PROCESSED_DATA)
PRIV_DATA_FULL_NAMES := $(addprefix $(PRIV_DATA_DIR)/,$(PRIV_DATA_NAMES))

DATA_FULL_NAMES := $(PRIV_DATA_FULL_NAMES) $(GARCH_DATA)

################################################
############## CREATION OF PDFS
################################################

# get list of all Julia source files for graphics
PICS_SCRIPTS_NAMES := $(notdir $(wildcard $(PICS_SRC)/*.jl))
PICS_FILE_NAMES := $(patsubst %.jl,%-1.svg,$(PICS_SCRIPTS_NAMES))
#RPICS_FILE_NAMES := missing_values-1.svg visualize_volatilities-1.svg market_trend_power-1.svg
PICS_FULL_NAMES := $(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)) 

PICS_FILE_NAMES_FOR_DELETION := $(patsubst %.jl,%-*.svg,$(PICS_SCRIPTS_NAMES))

# add possibility to add other pictures also
ALL_PICS_FULL_NAMES := $(PICS_FULL_NAMES)

# hierarchically highest target:
all: $(DATA_FULL_NAMES) $(ALL_PICS_FULL_NAMES)
.PHONY: all

# phony target to create all data
.PHONY: data
data: $(DATA_FULL_NAMES)

###############################################
############## CREATION OF MAIN_DATA:
###############################################

$(PRIV_DATA_DIR)/raw_data/SP500TickerSymbols.csv:
	cp $(HOME)/research/julia/EconDatasets/data/SP500TickerSymbols.csv $@

$(PRIV_DATA_DIR)/raw_data/SP500IndustryAffil.csv:
	cp $(HOME)/research/julia/EconDatasets/data/SP500Industries.csv $@

$(PRIV_DATA_DIR)/raw_data/SP500.csv: download_scripts/sp500_stock_price_data.jl $(PRIV_DATA_DIR)/raw_data/SP500TickerSymbols.csv
	julia download_scripts/sp500_stock_price_data.jl

$(PRIV_DATA_DIR)/processed_data/SP500.csv: data_scripts/pick_sp500_data.jl $(PRIV_DATA_DIR)/raw_data/SP500.csv
	julia data_scripts/pick_sp500_data.jl

$(PRIV_DATA_DIR)/raw_data/index_data.csv: download_scripts/index_price_data.jl
	julia download_scripts/index_price_data.jl

public_data/garch_norm_params.csv: data_scripts/garch_filtering.jl $(PRIV_DATA_DIR)/processed_data/SP500.csv
	julia data_scripts/garch_filtering.jl

# recipe for graphics
$(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)): $(PICS_DIR)/%-1.svg: $(PICS_SRC)/%.jl
	make data
	julia $<

# additional targets:
# TAGS files
# datasets
# executable files
# benchmark results
# unit tests

print-%:
	@echo '$*=$($*)'

# help - The default goal
.PHONY: help
help:
	$(MAKE) --print-data-base --question

.PHONY: nbconvert
nbconvert:
	julia utils/nbconvert.jl

.PHONY: clean
clean:
	rm -f Makefile~

# in case pics-3.svg has been deleted, while pics-1.svg still exists,
# updating rule for figures does not reproduce pics-3.svg
.PHONY: renew_all_julia_pics
renew_all_julia_pics:
	cd pics; rm -v $(PICS_FILE_NAMES_FOR_DELETION); cd ../; make

new:
	make
