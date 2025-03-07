TARGETS = \
	nametags.pdf \

all: ${TARGETS}

clean:
	touch ${TARGETS} pages.tex
	rm    ${TARGETS} pages.tex

mrproper: clean
	touch ${AUTOGEN_DEPS} d~ d.aux d.bbl d.bcf d.blg d.idx d.ilg d.ind d.lof d.log d.out d.run.xml d.toc
	rm    ${AUTOGEN_DEPS} *~ *.aux *.bbl *.bcf *.blg *.idx *.ilg *.ind *.lof *.log *.out *.run.xml *.toc


pages.tex: ../bin/generate-pages.exs ../data/
	../bin/generate-pages.exs > pages.tex


nametags.pdf: Makefile nametags.tex pages.tex
	lualatex nametags.tex
	lualatex nametags.tex

