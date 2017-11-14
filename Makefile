PYTHON := python

# targets that aren't filenames
.PHONY: all clean deploy

all: _includes/pubs.html presentations/index.html _site/index.html 

BUILDARGS :=
_site/index.html _site/wacas14/index.html:
	jekyll build $(BUILDARGS)

_includes/pubs.html: bib/pubs.bib bib/publications.tmpl
	$(PYTHON) mkdir.py _includes 
	$(PYTHON) bibble/bibble.py $+ > $@

presentations/index.html: _data/conferences.yml _data/talks.bib _data/posters.bib _data/courses.yml 
	$(PYTHON) presentations/presGen.py $+ > $@

_site/index.html: $(wildcard *.html) _includes/pubs.html _config.yml \
	_layouts/default.html

clean:
	$(RM) -r _site _includes/pubs.html presentations/index.html

HOST := yourwebpage.com
PATHSVR := www/
deploy: clean all
	rsync --compress --recursive --checksum --itemize-changes --delete -e ssh _site/ $(HOST):$(PATHSVR)
