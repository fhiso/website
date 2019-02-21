# FHISO Technical Website

This is the code used to build http://tech.fhiso.org/.  None of the
website's content is located here -- that can be found in one of the
following repositories:

* https://github.com/fhiso/tsc-governance
* https://github.com/fhiso/core-concepts-eg
* https://github.com/fhiso/lexicon-eg
* https://github.com/fhiso/sources-and-citations
* https://github.com/fhiso/bibliography
* https://github.com/fhiso/legacy-format
* https://github.com/fhiso/basic-concepts

The site is automatically updated every 20 minutes (at xx:00, xx:20 and
xx:40) by a cronjob running `update-all.sh`.  This does the following:

1.  Updates each git repository with a `git pull`.
2.  Build a snapshot of the lexicon.
3.  Generate the .htaccess file from the contents of `./htaccess/`.
4.  Install various static files (`png`s, `css`s, etc.).
5.  Run `./build-site.pl` to generate HTML and PDF versions for all files 
    listed in `tsc-governance/sitemap.xml` (and other `sitemap.xml` files
    imported from that).
6.  Install user management PHP code from `./include/` and `./account/`.  
7.  Install the CFPS PDF files, and populate its MySQL database.
8.  Upload an .htaccess file on the main server (`http://fhiso.org/`).
9.  Upload PDF versions of governance documents to `/files/governance/`
    on the main server.
10. Upload an HTML version of the bylaws and annual report to the main
    server via the WordPress API.
