#================================================================================================
# This python script creates/regenerates all research pages which have regenerate set to True in
# resPages.yml. It does this by making multiple calls to bibble.py to render each template. The 
# resPages.yml file specifies which pages to create and Research.bib specifies which publications
# should be displayed in said pages.
#
# Author: Tom Maullin (15/11/17)
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
import bibble as pubGen

# Set up the path.
PATH = os.path.dirname(os.path.abspath(__file__))

def main():
    
    # Read conferences Research page file
    with open(os.path.join(PATH, "..", "_data", "yml","resPages.yml"), 'r') as stream:
        #Load in the research page structure.
        resPages = yaml.load(stream)

    #Make each page in the resPages.yml file.
    for pageObj in resPages:
        if pageObj['regenerate']:
            #If the output directory doesn't exist, create it.
            if not os.path.isdir(os.path.join(os.path.dirname(PATH), 'research')):
                os.mkdir(os.path.join(os.path.dirname(PATH), 'research'))
            if not os.path.isdir(os.path.join(os.path.dirname(PATH), 'research', pageObj['name'])):
                os.mkdir(os.path.join(os.path.dirname(PATH), 'research', pageObj['name']))
            #Make the pages using functions in bibble.py
            pubGen.main(os.path.join(PATH, "..", "_data", "bib","research.bib"),
                        os.path.join(PATH, "..", "_layouts","resIndvTemplate.html"),
                        pageObj)

    # Load the template.
    tenv = jinja2.sandbox.SandboxedEnvironment()
    template = os.path.join(PATH, "..", "_layouts","resMainTemplate.html")
    with open(template) as f:
        tmpl = tenv.from_string(f.read())
        
    #Create context for the template.
    context = dict()
    context['resPages'] = resPages
    
    #Render the template for the main research page.
    out = tmpl.render(context)
    
    #Output.
    print(out.encode("utf8"))


if __name__ == '__main__':
    main(*sys.argv[1:])
