import sys
from pybtex.database.input import bibtex
import jinja2
import jinja2.sandbox
import re
from calendar import month_name
import codecs
import latexcodec
import os

# Set up the path.
PATH = os.path.dirname(os.path.abspath(__file__))

_months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
}

_pubtypes = {
    'unpublished': 9, 'techreport': 9, 'article': 8, 'book': 7, 'inbook': 7, 'incollection': 7, 
     'misc': 6, 'inproceedings': 5,
}

def translate_remove_brackets(to_translate, translate_to=u''):
    #This function removes {} brackets from a string. This is needed as brackets left over from
    #translating latex can cause issues when rendering templates. 
    brackets = u'{}'
    translate_table = dict((ord(char), translate_to) for char in brackets)
    return to_translate.translate(translate_table)

def _author_fmt(author):
    #This function formats an individual authors name.
    author = u' '.join(author.first() + author.middle() + author.last())
    return translate_remove_brackets(author)

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
            #Move onto next letter.
            currentLetter = currentLetter + 1
            #If we have 6 author names (and therefore 6 commas) change the remaining names to et al.
            if commaCount == 6:
                shortenedAuthorList = authorList[0:(currentLetter)]+' et al'
                shortened = True

    return shortenedAuthorList

def _andlist(ss, sep=', ', seplast=', and ', septwo=' and '):
    #This function creates a list of authors from a set of authors.
    if len(ss) <= 1:
        return ''.join(ss)
    elif len(ss) == 2:
        return septwo.join(ss)
    else:
        return sep.join(ss[:-1]) + seplast + ss[-1]

def _author_list(authors):
    #This function returns a list of authors.
    authorList = _author_Shorten(_andlist(map(_author_fmt, authors)))
    return authorList

def _venue_type(entry):
    #This function returns the type of venue that the entry we are looking at was published in.
    venuetype = ''
    if entry.type == 'inbook':
        venuetype = 'Chapter in '
    elif entry.type == 'techreport':
        venuetype = 'Technical Report '
    elif entry.type == 'phdthesis':
        venuetype = 'Ph.D. thesis, {}'.format(entry.fields['school'])
    return venuetype

def _type(entry):
    #This function returns the type of entry we are looking at.
    pub_type = ''
    if entry.type == 'misc':
        pub_type = 'Miscealeneous '
    elif entry.type == 'article':
        pub_type = 'Articles'
    elif entry.type == 'unpublished' or entry.type == 'techreport':
        pub_type = 'Preprints'
    elif entry.type == 'book' or entry.type == 'incollection':
        pub_type = 'Books & Chapters'
    elif entry.type == 'inproceedings':
        pub_type = 'In Proceedings'
    else:
        pub_type = entry.type

    return pub_type

def _pageno(entry):
    #This function returns page numbers.
    f = entry.fields
    pageno = u''
    if 'pages' in f:
        pageno = f['pages']
    return translate_remove_brackets(pageno)

def _doi(entry):
    #This function returns the doi of an entry.
    f = entry.fields
    doi = u''
    if 'doi' in f:
        doi = f['doi']
    return translate_remove_brackets(doi) 

def _venue(entry):
    #This function returns details about where an entry was published.
    f = entry.fields
    venue = u''
    if entry.type == 'article':
        venue = u'<i>' + f['journal'] + u'</i>'
        try:
            if f['volume'] and f['number']:
                venue += u' {0}({1})'.format(f['volume'], f['number'])
        except KeyError:
            pass
    elif entry.type == 'inproceedings':
        venue = f['booktitle']
        try:
            if f['series']:
                venue += u' ({})'.format(f['series'])
        except KeyError:
            pass
    elif entry.type == 'inbook' or entry.type == 'incollection':
        venue = f['title']
    elif entry.type == 'techreport':
        if 'number' in f and 'institution' in f:
            venue = u'{0}, {1}'.format(f['number'], f['institution'])
        elif 'booktitle' in f:
            venue = f['booktitle']
        else:
            venue = u''
    elif entry.type == 'phdthesis':
        venue = u''
    elif entry.type == 'unpublished':
        venue = f['journal']
    else:
        venue = u'Unknown venue (type={})'.format(entry.type)

    venue = translate_remove_brackets(venue)
    return venue

def _title(entry):
    #This function returns the title of an entry.
    if entry.type == 'inbook':
        title = entry.fields['chapter']
    else:
        title = entry.fields['title']

    # remove curlies from titles -- useful in TeX, not here
    title = translate_remove_brackets(title)
    return title

def _main_url(entry):
    #This function returns the main URL of an entry.
    urlfields = ('url', 'ee')
    for f in urlfields:
        if f in entry.fields:
            urlList = entry.fields[f]
            return translate_remove_brackets(urlList.split(' ', 1)[0])
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
    #This function returns the name of a month given its number. e.g. 8 -> August
    try:
        return month_name[int(monthnum)]
    except:
        return ''

def _sortkey(entry):
    #This entry creates a key based on the year of an entry in order for the entries to be later sorted.
    e = entry.fields
    year =  '{:04d}'.format(int(e['year']))

    return year + '{:04d}'.format(_pubtypes[entry.type])

def main(bibfile, template, pageObj):

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
    tenv.filters['pageno'] = _pageno
    tenv.filters['doi'] = _doi
    with open(template) as f:
        tmpl = tenv.from_string(f.read())

    #Open the parser.
    parser = bibtex.Parser()
    
    # Parse the BibTeX file.
    with codecs.open(bibfile, encoding="latex") as stream:
        db = parser.parse_stream(stream)

    # Include the bibliography key in each entry.
    for k, v in db.entries.items():
        v.fields['key'] = k

    # Render the template.
    bib_sorted = sorted(db.entries.values(), key=_sortkey, reverse=True)

    entries = [(bib_sorted[0], None, None)]
    prev_year = bib_sorted[0].fields['year']
    prev_type = bib_sorted[0].type

    #We already have the first entry (bib_sorted[0]).
    isFirst = True

    for bib in bib_sorted:

        #Append all entries after the first.
        if isFirst:
            isFirst = False
        else:
            entries.append((bib, prev_year, prev_type))
            prev_year = bib.fields['year']
            prev_type = bib.type

    context = dict()
    context['entries'] = entries
    
    #The pageObject dictates which page we are displaying if we are
    #displaying research pages. It is ignored in the publications
    #template.
    context['pageObj'] = pageObj

    #Render the template
    out = tmpl.render(context)
    
    #If we are creating a publications page just print out the template.
    if pageObj == 'Publications':
        print(out.encode("utf-8"))
    #If we are looking at Research pages work out where to save them and output
    #to there.
    else:
        fname = os.path.join(os.path.dirname(PATH), 'Research', pageObj['name'], 'index.html')
        with open(fname, 'w') as f:
            f.write(out.encode("utf8"))

if __name__ == '__main__':
    main(*sys.argv[1:])
