# NISOx website

Website of the NISOx research group at the Oxford Big Data Institute based on [Jekyll](https://jekyllrb.com/) and [Github-pages](https://pages.github.com/) and [Pybtex][] to generate the publication list. 

Preview is available at: https://nisox-bdi.github.io/.

## How to update the website?
Except for the page including the publication list (cf. [below](#how-to-update-the-publication-list)), any new change pushed to the `master` branch of the current repository will automatically be reflected on the website. It is stronly advised to preview the changes locally before pushing to GitHub (cf. [section 'building'](#building)).

## How to update the publication list?
Every time the `bib/pubs.bib` file is updated, the corresponding HTML page (located in `_includes/pubs.html`) has to be updated with:
```
make
```

Note that `bib/pubs.bib` cannot contain any non-ASCII character or `make` will fail. To identify non-ASCII character in a document, you can use on Mac `pcregrep --color='auto' -n "[\x80-\xFF]" bib/test.bib ` (cf. [this post](https://stackoverflow.com/questions/24939813/recursively-search-in-files-for-a-range-of-unicode-characters)).

## Acknowlegments

This website was built using the [Research Group Web Site Template](https://github.com/uwsampa/research-group-web) developed by [Computer Architecture Lab @ University of Washington](https://github.com/uwsampa). This work is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).

## Template documentation

This is an exerp of the template documentation. The full documentation is available in the [original repository]().

Features
--------

* Thanks to [Jekyll][], content is just text files. So even faculty should be able to figure it out.
* Publications list generated from BibTeX.
* Personnel list. Organize your professors, students, staff, and alumni.
* Combined news stream and blog posts.
* Easily extensible navigation bar.
* Responsive (mobile-ready) design based on [Bootstrap][].

[Bootstrap]: http://getbootstrap.com/


Setup
-----

1. Install the dependencies. You will need [Python][], [Pybtex][] (`pip install pybtex`), and [Jekyll][] (`gem install jekyll`).
2. [Fork][] this repository on GitHub.
3. Clone the fork (along with its submodules) to your own machine: `git clone --recursive git@github.com:yourgroup/research-group-web.git`.
4. Add an "upstream" remote for the original repository so you can stay abreast of bugfixes: `git remote add upstream git://github.com/uwsampa/research-group-web.git`.
5. Customize. Start with the `_config.yml` file, where you enter the name of the site and its URL.
6. Type `make` to build the site and then run `jekyll serve -w` to view your site.
7. Keep adding content. See below for instructions for each of the various sections.
8. Periodically pull from the upstream repository: `git pull upstream master`.

[Python]: https://www.python.org/
[Fork]: https://github.com/uwsampa/research-group-web/fork


Publication List
----------------

The list of publications is in `bib/pubs.bib`. Typing `make` will generate `pubs.html`, which contains a pretty, sorted HTML-formatted list of papers. The public page, `publications.html`, also has a link to download the original BibTeX.


News Items and Blog Posts
-------------------------

For both long-form blog posts and short news updates, we use Jekyll's blogging system. To post a new item of either type, you create a file in the `_posts` directory using the naming convention `YYYY-MM-DD-title-for-url.md`. The date part of the filename always matters; the title part is currently only used for full blog posts (but is still required for news updates).

The file must begin with [YAML front matter][yfm]. For news updates, use this:

    ---
    layout: post
    shortnews: true
    ---

For full blog posts, use this format:

    ---
    layout: post
    title:  "Some Great Title Here"
    ---

And concoct a page title for your post. The body of the post goes after the `---` in either case.

[yfm]: http://jekyllrb.com/docs/frontmatter/


Personnel
---------

People are listed in a [YAML][] file in `_data/people.yml`. You can list the name, link, bio, and role of each person. Roles (e.g., "Faculty", "Staff", and "Students") are defined in `_config.yml`.

[YAML]: https://en.wikipedia.org/wiki/YAML


Building
--------

The requirements for building the site are:

* [Jekyll][]: run `gem install jekyll`
* [Pybtex][]: run `pip install pybtex`
* [bibble][]: included as a submodule. Because git is cruel, you need to use
  `git clone --recursive URL` or issue the commands `git submodule init ; git
  submodule update` to check out the dependency.
* ssh and rsync, only if you want to deploy directly.

`make` compiles the bibliography and the website content to the `_site`
directory. 

To preview the site, run: 
```
jekyll serve -w
``` 
and head to http://0.0.0.0:4000.


[Jekyll]: http://jekyllrb.com/
[bibble]: https://github.com/sampsyo/bibble/
[pybtex]: http://pybtex.sourceforge.net
