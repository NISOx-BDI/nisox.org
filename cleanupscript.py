#================================================================================================
# This python script clears all script-generated research and presentation pages. It is run when
# 'make clean' is run and any files it deletes should be reconstructed by resGen.py or presGen.py
# when 'make' is next run.
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
import shutil

# Set up the path.
PATH = os.path.dirname(os.path.abspath(__file__))

# Read Research pages file
with open(os.path.join(PATH, "_data_yml","resPages.yml"), 'r') as stream:
    #Load in the research page structure.
    resPages = yaml.load(stream)

    #Remove any code generated files.
    for pageObj in resPages:
        if pageObj['regenerate']:
            if os.path.isdir(os.path.join(PATH, 'research', pageObj['name'])):
                shutil.rmtree(os.path.join(PATH, "research", pageObj['name']))

# Read conferences file
with open(os.path.join(PATH, "_data_yml","conferences.yml"), 'r') as stream:
    #Load in the research page structure.
    conferences = yaml.load(stream)

    #Remove any code generated files.
    for conference in conferences:
        if os.path.isdir(os.path.join(PATH, 'presentations', conference['name'])):
                shutil.rmtree(os.path.join(PATH, "presentations", conference['name']))
