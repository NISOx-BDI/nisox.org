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
    with open(os.path.join(PATH, "..", "_data","resPages.yml"), 'r') as stream:
        #Load in the research page structure.
        resPages = yaml.load(stream)

    #Make each page in the resPages.yml file.
    for pageObj in resPages:
        if pageObj['regenerate']:
            #If the output directory doesn't exist, create it.
            if not os.path.isdir(os.path.join(os.path.dirname(PATH), 'Research', pageObj['name'])):
                os.mkdir(os.path.join(os.path.dirname(PATH), 'Research', pageObj['name']))
            #Make the pages
            pubGen.main(os.path.join(PATH, "..", "_data","research.bib"),
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
    #fname = os.path.join(os.path.dirname(PATH), 'Research', 'index.html')
    #with open(fname, 'w') as f:
    #    f.write(out.encode("utf8"))
    print(out.encode("utf8"))



if __name__ == '__main__':
    main(*sys.argv[1:])
