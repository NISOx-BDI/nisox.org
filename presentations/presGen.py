#================================================================================================
# This python script uses the templates in the layouts folder to generate all presentation
# pages using the YAML files in the data folder.
#
# Author: Tom Maullin (23/10/17)
#================================================================================================

import yaml
import io
import os
from jinja2 import Environment, FileSystemLoader
import jinja2.sandbox

# Set up the path and template environment.
PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_ENVIRONMENT = Environment(
    autoescape=False,
    loader=FileSystemLoader(os.path.join(PATH, '..', '_layouts')),
    trim_blocks=False)
 
# This function renders the template "template_filename" using the "context" structure.
def render_template(template_filename, context):
    return TEMPLATE_ENVIRONMENT.get_template(template_filename).render(context)
 
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
    
    # Read talks YAML file
    with open(os.path.join(PATH, "..", "_data","talks.yml"), 'r') as stream:
        #Load in the talk structure.
        talk_struct = yaml.load(stream)

    # Read posters YAML file
    with open(os.path.join(PATH, "..", "_data","posters.yml"), 'r') as stream:
        #Load in the poster structure.
        poster_struct = yaml.load(stream)

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
            #Generate a page for each conference
            create_index_html(contextCourse, 'course')

 
########################################
 
if __name__ == "__main__":
    main()


