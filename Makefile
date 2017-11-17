PYTHON := python

# targets that aren't filenames
.PHONY: all clean deploy

all: _includes/pubs.html presentations/index.html _site/index.html research/index.html

BUILDARGS :=
_site/index.html _site/wacas14/index.html:
	jekyll build $(BUILDARGS)

_includes/pubs.html: _data_bib/pubs.bib _data_bib/publications.tmpl
	$(PYTHON) mkdir.py _includes 
	$(PYTHON) bibble/bibble.py $+ 'Publications' > $@ 

presentations/index.html: _data_yml/conferences.yml _data_bib/talks.bib _data_bib/posters.bib _data_yml/courses.yml 
	$(PYTHON) bibble/presGen.py $+ > $@

research/index.html: _data_bib/research.bib _data_yml/resPages.yml
	$(PYTHON) bibble/resGen.py > $@ 

_site/index.html: $(wildcard *.html) _includes/pubs.html _config.yml \
	_layouts/default.html

clean:
	$(RM) -r _site _includes/pubs.html presentations/index.html research/index.html
	$(PYTHON) cleanupscript.py

HOST := yourwebpage.com
PATHSVR := www/
deploy: clean all
	rsync --compress --recursive --checksum --itemize-changes --delete -e ssh _site/ $(HOST):$(PATHSVR)
