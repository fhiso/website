# FHISO Technical Website

This is the code used to build http://tech.fhiso.org/.  None of the
website's content is located here -- that can be found in one of the
following repositories:

* https://github.com/fhiso/tsc-governance
* https://github.com/fhiso/core-concepts-eg
* https://github.com/fhiso/lexicon-eg
* https://github.com/fhiso/sources-and-citations-eg
* https://github.com/fhiso/bibliography

The site is automatically updated every 20 minutes (at xx:00, xx:20 and
xx:40) by a cronjob running `update-all.sh`.  This does the following:

1. Updates each git repository with a `git pull`.
2. Build a snapshot of the lexicon.
3. Generate the .htaccess file from the contents of `./htaccess/`.
4. Install various static files (`png`s, `css`s, etc.).
5. Run `./build-site.pl` to generate HTML and PDF versions for all files 
   listed in `tsc-governance/sitemap.xml` (and other `sitemap.xml` files
   imported from that).
6. Build and install user management PHP code from `./include/` and
   `./account/`.  
7. Install the CFPS PDF files, and populate its MySQL database.
8. Install `tsc-governance/term.map` to control 303 redirections on
   `http://terms.fhiso.org/`.
9. Install an .htaccess file on the main server (`http://fhiso.org/`).

