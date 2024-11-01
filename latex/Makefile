main.pdf: main.tex *.tex *.bib images/*
	pdflatex main
	bibtex main
	pdflatex main
	pdflatex main

clean:
	find ./ -regex '.*main.*' | grep -v 'tex' | xargs rm
