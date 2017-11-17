PYTHON := python

# targets that aren't filenames
.PHONY: all clean deploy

all: publications/index.html presentations/index.html _site/index.html research/index.html

BUILDARGS :=
_site/index.html _site/wacas14/index.html:
	jekyll build $(BUILDARGS)

publications/index.html: _data/bib/pubs.bib _layouts/publications.tmpl
	$(PYTHON) mkdir.py _includes 
	$(PYTHON) bibble/bibble.py $+ 'Publications' > $@ 

presentations/index.html: _data/yml/conferences.yml _data/bib/talks.bib _data/bib/posters.bib _data/yml/courses.yml 
	$(PYTHON) bibble/presGen.py $+ > $@

research/index.html: _data/bib/research.bib _data/yml/resPages.yml
	$(PYTHON) bibble/resGen.py > $@ 

_site/index.html: $(wildcard *.html) publications/index.html _config.yml \
	_layouts/default.html

clean:
	$(RM) -r _site _includes/pubs.html presentations/index.html research/index.html publications/index.html
	$(PYTHON) cleanupscript.py

HOST := yourwebpage.com
PATHSVR := www/
deploy: clean all
	rsync --compress --recursive --checksum --itemize-changes --delete -e ssh _site/ $(HOST):$(PATHSVR)
