prefix=smmcts-ggp
dbdir=~/Dropbox/smmcts-ggp

pdf: $(prefix).tex $(prefix).bib
	latexmk -pdf $(prefix).tex

view: pdf
	evince $(prefix).pdf

putdb:
	cp *.cls *.bst *.bib *.tex Makefile *.pdf *.bst $(dbdir)
	#cp figures/* $(dbdir)/figures

getdb:  
	cp $(dbdir)/*.tex $(dbdir)/*.bst $(dbdir)/*.cls $(dbdir)/*.bib $(dbdir)/Makefile $(dbdir)/*.bst .
	#cp $(dbdir)/figures/* figures

clean:
	latexmk -c
	rm -f *~ *.bbl
	rm -f $(prefix).pdf

