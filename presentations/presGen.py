#================================================================================================
# This python script uses the templates in the layouts folder to generate all presentation
# pages using the YAML files in the data folder.
#
# Author: Tom Maullin (23/10/17)
#================================================================================================

import sys
from pybtex.database.input import bibtex
import yaml
import io
import os
from jinja2 import Environment, FileSystemLoader
import jinja2.sandbox
from calendar import month_name
import re
import codecs
import latexcodec
import os

_months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
}

# Set up the path and template environment.
PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_ENVIRONMENT = Environment(
    autoescape=False,
    loader=FileSystemLoader(os.path.join(PATH, '..', '_layouts')),
    trim_blocks=False)

def translate_remove_brackets(to_translate, translate_to=u''):
    brackets = u'{}'
    translate_table = dict((ord(char), translate_to) for char in brackets)
    return to_translate.translate(translate_table)

def _author_fmt(author):
    author = u' '.join(author.first() + author.middle() + author.last())
    return translate_remove_brackets(author)

def _author_Shorten(authorList, numAuthors):
    #This function takes in a list of authors and if there are more than 6, outputs the first 6 authors and et al.

    if authorList.count(',') < numAuthors:
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
            if commaCount == numAuthors:
                shortenedAuthorList = authorList[0:(currentLetter)]+u' et al'
                shortened = True

    return shortenedAuthorList

def _andlist(ss, sep=', ', seplast=', and ', septwo=' and '):
    if len(ss) <= 1:
        return ''.join(ss)
    elif len(ss) == 2:
        return septwo.join(ss)
    else:
        return sep.join(ss[:-1]) + seplast + ss[-1]

def _author_list_posters(authors):
    authorList = _author_Shorten(_andlist(map(_author_fmt, authors)), 1)
    return authorList

def _author_list_presentations(authors):
    authorList = _author_Shorten(_andlist(map(_author_fmt, authors)), 6)
    return authorList

def _multiple_authors(authors):
    authorList = _author_list_posters(authors)
    if ',' in authorList or 'and' in authorList or 'et al' in authorList:
        return True
    else:
        return False
    
def _title(entry):
    title = entry.fields['title']

    # remove curlies from titles -- useful in TeX, not here
    title = translate_remove_brackets(title)
    return title

def _main_url(entry):
    urlfields = ('url', 'ee')
    for f in urlfields:
        if f in entry.fields:
            urlList = entry.fields[f]
            return translate_remove_brackets(urlList.split(' ', 1)[0])
    return None

def _doi(entry):
    f = entry.fields
    doi = u''
    if 'doi' in f:
        doi = f['doi']
    return translate_remove_brackets(doi) 

def _conf(entry):
    conf = entry.fields['conf']
    return conf

def _month_name (monthnum):
    try:
        return month_name[int(monthnum)]
    except:
        return ''

def _conf_details(entry):
    confDet = entry.fields['number'] +  u'-<b>' + entry.fields['day'] + u'</b>'
    return confDet
    
# This function renders the template "template_filename" using the "context" structure.
def render_template(template_filename, context):

    # Load the template.
    tenv = jinja2.sandbox.SandboxedEnvironment()
    
    #Add filters.
    tenv.filters['title'] = _title
    tenv.filters['conf_details'] = _conf_details
    tenv.filters['multiple_authors'] = _multiple_authors
    tenv.filters['author_fmt'] = _author_fmt
    tenv.filters['author_list_pr'] = _author_list_presentations
    tenv.filters['author_list_po'] = _author_list_posters
    tenv.filters['monthname'] = _month_name
    tenv.filters['conf'] = _conf
    tenv.filters['main_url'] = _main_url
    tenv.filters['doi'] = _doi
    with open(os.path.join(PATH, '..', '_layouts', template_filename)) as f:
        tmpl = tenv.from_string(f.read())

    return tmpl.render(context)
 

#This function retrieves data from a bibtex file.
def getBibStruct(bibfile):

    #Open the parser.
    parser = bibtex.Parser()

    # Parse the BibTeX file.
    with codecs.open(bibfile, encoding="latex") as stream:
        db = parser.parse_stream(stream)

    stream.close()
    
    return db.entries.values()

# This function creates a HTML file using the "context" structure. The variable "outputInstruct"
# takes the values 'conf' for a conference page, 'pres' for the main presentations page or 'course'
# for a course page.
def create_index_html(context, outputInstruct):
    
    #Creating a conference page.
    if outputInstruct == 'conf':
        conf = context['conference']
        
        #If the output directory doesn't exist, create it.
        if not os.path.isdir(os.path.join(os.path.dirname(PATH), 'presentations', conf['name'])):
            os.mkdir(os.path.join(os.path.dirname(PATH), 'presentations', conf['name']))

        #Create the name of the output file.
        fname = os.path.join(os.path.dirname(PATH), 'presentations', conf['name'], 'index.html')
        
        #Render the template and output.
        with open(fname, 'w') as f:
            html = render_template('confTemplate.html',context)
            f.write(html)

    #Creating the main presentations page.  
    if outputInstruct == 'pres':
        
        #Render template and print (output is decided by makefile.
        html = render_template('presTemplate.html',context)
        print(html)

    #Creating a course page.
    if outputInstruct == 'course':

        #Obtain the course from the context.
        course = context['course']

        #Create the name of the output file.
        fname = os.path.join(os.path.dirname(PATH), 'presentations', course['conf'], course['name'] + '.html')

        #Render the template and output.
        with open(fname, 'w') as f:
            html = render_template('courseTemplate.html',context)
            f.write(html)
 
 
def main():

    # Create a course specific context object.
    contextCourse = dict()
    
    # Create a conference specific context object.
    contextConf = dict()

    # Create a context object for the main presentations page
    contextPres = dict()

    # Read talks bib file
    talk_struct = getBibStruct(os.path.join(PATH, "..", "_data","talks.bib"));

    # Read posters bib file 
    poster_struct = getBibStruct(os.path.join(PATH, "..", "_data","posters.bib"));
    
    # Read courses YAML file
    with open(os.path.join(PATH, "..", "_data","courses.yml"), 'r') as stream:
        #Load in the poster structure.
        courses_struct = yaml.load(stream)
        
    # Read conferences YAML file
    with open(os.path.join(PATH, "..", "_data","conferences.yml"), 'r') as stream:
        #Load in the conference structure.
        conferences = yaml.load(stream)

        #Create the main presentations page.
        contextPres['conferences'] = conferences
        create_index_html(contextPres, 'pres')

        for i in range(0, len(conferences)):
            #Retrieve data for a conference.
            contextConf['conference'] = conferences[i]
            contextConf['talks'] = talk_struct
            contextConf['posters'] = poster_struct
            contextConf['courses'] = courses_struct
            #Generate a page for each conference
            create_index_html(contextConf, 'conf')

        for i in range(0, len(courses_struct)):
            contextCourse['course'] = courses_struct[i]
            contextCourse['talks'] = talk_struct
            #Generate a page for each conference
            create_index_html(contextCourse, 'course')

 
########################################
 
if __name__ == "__main__":
    main()


