prefix=smmcts-ggp
pdf: $(prefix).tex $(prefix).bib
	latexmk -pdf $(prefix).tex

view: pdf
	evince $(prefix).pdf

clean:
	latexmk -c
	rm -f *~ *.bbl
	rm -f $(prefix).pdf

