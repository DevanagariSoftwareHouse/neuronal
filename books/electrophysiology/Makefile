TEX := pdflatex
ROOT := main
BUILD := build
.PHONY: pdf clean figures-preview
pdf:
	python3 ../tools/check_sources.py
	mkdir -p $(BUILD)
	$(TEX) -interaction=nonstopmode -halt-on-error -file-line-error -output-directory=$(BUILD) $(ROOT).tex
	BIBINPUTS=refs: bibtex $(BUILD)/$(ROOT)
	$(TEX) -interaction=nonstopmode -halt-on-error -file-line-error -output-directory=$(BUILD) $(ROOT).tex
	$(TEX) -interaction=nonstopmode -halt-on-error -file-line-error -output-directory=$(BUILD) $(ROOT).tex
clean:
	rm -rf $(BUILD)

# Draft preview only: no MATLAB prerequisite for the regular pdf target.
MATLAB ?= matlab-r2019a
figures-preview:
	$(MATLAB) -batch "addpath('../../matlab/figures'); build_book_figures();"
	cp ../../matlab/build/figures/fig_*.pdf figures/generated/
