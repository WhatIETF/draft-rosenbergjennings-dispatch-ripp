#
# Makefile to build Internet Drafts from markdown using mmarc
#

SRC  := $(wildcard draft-*.md)
TXT  := $(patsubst %.md,%.txt,$(SRC))
HTML := $(patsubst %.md,%.html,$(SRC))

all: $(TXT) $(HTML) ripp-api.html ripp-api.md 

clean:
	rm -f *~ draft*.txt draft-*.html draft-*.xml

ripp-api.md: ripp-api.raml 
	raml2html --theme raml2html-markdown-theme ripp-api.raml > ripp-api.md

ripp-api.html: ripp-api.raml 
	raml2html ripp-api.raml > ripp-api.html


%.html: %.xml
	xml2rfc --html $^ -o $@

%.txt: %.xml
	xml2rfc --text $^ -o $@

.PRECIOUS: %.xml
%.xml: %.md
	mmark -xml2 -page $^ $@ 
