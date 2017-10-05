import sys
from pybtex.database.input import bibtex
import jinja2
import jinja2.sandbox
import re
from calendar import month_name

_months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
}

_pubtypes = {
    'unpublished': 9, 'techreport': 9, 'article': 8, 'book': 7, 'inbook': 7, 'incollection': 7, 
     'misc': 6, 'inproceedings': 5,
}

def _author_fmt(author):
    return u' '.join(author.first() + author.middle() + author.last())

def _author_Shorten(authorList):
    #This function takes in a list of authors and if there are more than 6, outputs the first 6 authors and et al.

    if authorList.count(',') < 6:
        shortenedAuthorList = authorList
    else:
        commaCount = 0
        currentLetter = 0
        shortened = False

        while(shortened == False):
            #Count the number of commas.
            if authorList[currentLetter] == ',':
                commaCount = commaCount +1
            #Move onto next letter
            currentLetter = currentLetter + 1
            #If we have 6 author names (and therefore 6 commas) change the remaining names to et al.
            if commaCount == 6:
                shortenedAuthorList = authorList[0:(currentLetter)]+' et al'
                shortened = True

    return shortenedAuthorList

def _andlist(ss, sep=', ', seplast=', and ', septwo=' and '):
    if len(ss) <= 1:
        return ''.join(ss)
    elif len(ss) == 2:
        return septwo.join(ss)
    else:
        return sep.join(ss[:-1]) + seplast + ss[-1]

def _author_list(authors):
    return _author_Shorten(_andlist(map(_author_fmt, authors)))

def _venue_type(entry):
    venuetype = ''
    if entry.type == 'inbook':
        venuetype = 'Chapter in '
    elif entry.type == 'techreport':
        venuetype = 'Technical Report '
    elif entry.type == 'phdthesis':
        venuetype = 'Ph.D. thesis, {}'.format(entry.fields['school'])
    return venuetype

def _type(entry):
    pub_type = ''
    if entry.type == 'misc':
        pub_type = 'Miscealeneous '
    elif entry.type == 'article':
        pub_type = 'Articles'
    elif entry.type == 'unpublished' or entry.type == 'techreport':
        pub_type = 'Preprints'
    elif entry.type == 'book' or entry.type == 'incollection':
        pub_type = 'Books & Chapters'
    else:
        pub_type = entry.type

    return pub_type


def _venue(entry):
    f = entry.fields
    venue = ''
    if entry.type == 'article':
        venue = f['journal']
        try:
            if f['volume'] and f['number']:
                venue += ' {0}({1})'.format(f['volume'], f['number'])
        except KeyError:
            pass
    elif entry.type == 'inproceedings':
        venue = f['booktitle']
        try:
            if f['series']:
                venue += ' ({})'.format(f['series'])
        except KeyError:
            pass
    elif entry.type == 'inbook':
        venue = f['title']
    elif entry.type == 'techreport':
        if 'number' in f and 'institution' in f:
            venue = '{0}, {1}'.format(f['number'], f['institution'])
        else:
            venue = ''
    elif entry.type == 'phdthesis':
        venue = ''
    elif entry.type == 'unpublished':
        venue = f['journal']
    else:
        venue = 'Unknown venue (type={})'.format(entry.type)
    return venue

def _title(entry):
    if entry.type == 'inbook':
        title = entry.fields['chapter']
    else:
        title = entry.fields['title']

    # remove curlies from titles -- useful in TeX, not here
    title = title.translate(None, '{}')
    return title

def _main_url(entry):
    urlfields = ('url', 'ee')
    for f in urlfields:
        if f in entry.fields:
            return entry.fields[f]
    return None

def _extra_urls(entry):
    """Returns a dict of URL types to URLs, e.g.
       { 'nytimes': 'http://nytimes.com/story/about/research.html',
          ... }
    """
    urls = {}
    for k, v in entry.fields.iteritems():
        if not k.endswith('_url'):
            continue
        k = k[:-4]
        urltype = k.replace('_', ' ')
        urls[urltype] = v
    return urls

def _month_match (mon):
    if re.match('^[0-9]+$', mon):
        return int(mon)
    return _months[mon.lower()[:3]]

def _month_name (monthnum):
    try:
        return month_name[int(monthnum)]
    except:
        return ''

def _sortkey(entry):
    e = entry.fields
    year =  '{:04d}'.format(int(e['year']))

    return year + '{:04d}'.format(_pubtypes[entry.type])

def main(bibfile, template):
    # Load the template.
    tenv = jinja2.sandbox.SandboxedEnvironment()
    tenv.filters['author_fmt'] = _author_fmt
    tenv.filters['author_list'] = _author_list
    tenv.filters['title'] = _title
    tenv.filters['venue_type'] = _venue_type
    tenv.filters['venue'] = _venue
    tenv.filters['main_url'] = _main_url
    tenv.filters['extra_urls'] = _extra_urls
    tenv.filters['monthname'] = _month_name
    tenv.filters['type'] = _type
    tenv.filters['sortkey'] = _sortkey
    with open(template) as f:
        tmpl = tenv.from_string(f.read())

    # Parse the BibTeX file.
    with open(bibfile) as f:
        db = bibtex.Parser().parse_stream(f)

    # Include the bibliography key in each entry.
    for k, v in db.entries.items():
        v.fields['key'] = k

    # Render the template.
    bib_sorted = sorted(db.entries.values(), key=_sortkey, reverse=True)

    entries = [(bib_sorted[0], None, None)]
    prev_year = bib_sorted[0].fields['year']
    prev_type = bib_sorted[0].type
    for bib in bib_sorted:
        entries.append((bib, prev_year, prev_type))
        prev_year = bib.fields['year']
        prev_type = bib.type

    out = tmpl.render(entries=entries)
    print(out)

if __name__ == '__main__':
    main(*sys.argv[1:])
