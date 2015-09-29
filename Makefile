
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

SP500_RAW_DATA := raw_data/SP500TickerSymbols.csv raw_data/SP500.csv raw_data/SP500IndustryAffil.csv
DATA_NAMES := $(SP500_RAW_DATA)
DATA_FULL_NAMES := $(addprefix $(PRIV_DATA_DIR)/,$(DATA_NAMES))

################################################
############## CREATION OF PDFS
################################################

# get list of all Julia source files for graphics
PICS_SCRIPTS_NAMES := $(notdir $(wildcard $(PICS_SRC)/*.jl))
PICS_FILE_NAMES := $(patsubst %.jl,%-1.pdf,$(PICS_SCRIPTS_NAMES))
#RPICS_FILE_NAMES := missing_values-1.pdf visualize_volatilities-1.pdf market_trend_power-1.pdf
PICS_FULL_NAMES := $(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)) 

PICS_FILE_NAMES_FOR_DELETION := $(patsubst %.jl,%-*.pdf,$(PICS_SCRIPTS_NAMES))

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

$(PRIV_DATA_DIR)/raw_data/SP500.csv: download_scripts/sp500_stock_price_data.jl $(PRIV_DATA_DIR)/raw_data/SP500TickerSymbols.csv
	julia download_scripts/sp500_stock_price_data.jl

$(PRIV_DATA_DIR)/raw_data/SP500IndustryAffil.csv:
	cp $(HOME)/research/julia/EconDatasets/data/SP500Industries.csv $@

# recipe for r graphics
$(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)): $(PICS_DIR)/%-1.pdf: $(PICS_SRC)/%.jl
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

.PHONY: clean
clean:
	rm -f Makefile~

# in case pics-3.pdf has been deleted, while pics-1.pdf still exists,
# updating rule for figures does not reproduce pics-3.pdf
.PHONY: renew_all_julia_pics
renew_all_julia_pics:
	cd pics; rm -v $(PICS_FILE_NAMES_FOR_DELETION); cd ../; make

new:
	make
