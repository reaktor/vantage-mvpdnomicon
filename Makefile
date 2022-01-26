mvpds := altice charter comcast dish directv
source_dirs := $(addprefix mvpd/,$(mvpds))
translation_dirs := $(addprefix translated/mvpd/,$(mvpds))

source_altice_files := $(shell find mvpd/altice -name 'Viacom_Altice_Daily_Report*.xlsx')
translated_altice_files := $(addsuffix .csv,$(addprefix translated/,$(source_altice_files)))

source_charter_files_xlsx := $(shell find mvpd/charter -name '*.xlsx')
translated_charter_files_xlsx := $(addsuffix .csv,$(addprefix translated/,$(source_charter_files_xlsx)))
source_charter_files_txt := $(shell find mvpd/charter -name '*.txt')
translated_charter_files_txt := $(addsuffix .csv,$(addprefix translated/,$(source_charter_files_txt)))
source_charter_files := $(source_charter_files_xlsx) $(source_charter_files_txt)
translated_charter_files := $(translated_charter_files_xlsx) $(translated_charter_files_txt)

source_files := $(source_altice_files) $(source_charter_files)
translated_files := $(translated_altice_files) $(translated_charter_files)

all: altice charter

sync:
	aws s3 sync s3://datasolutions-vantage/mvpd/ mvpd

translated/mvpd/altice/%.xlsx.csv: mvpd/altice/%.xlsx
	xlsx2csv --all --exclude_sheet_pattern "Campaign to Date" --sheetdelimiter "" \
		--dateformat "%Y-%m-%d" --timeformat "%H:%M:%S" $< > $@

translated/mvpd/charter/%.xlsx.csv: mvpd/charter/%.xlsx
	xlsx2csv --all --exclude_sheet_pattern "Campaign to Date" --sheetdelimiter "" \
		--dateformat "%Y-%m-%d" --timeformat "%H:%M:%S" $< > $@

translated/mvpd/charter/%.txt.csv: mvpd/charter/%.txt
	xsv fmt -d '|' $< > $@

altice: $(translated_altice_files)

charter: $(translated_charter_files)

clean:
	rm -v $(translated_files)

.PHONY: all clean sync