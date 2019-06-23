# Makefile to build Internet Drafts from markdown using mmarc


DRAFT = draft-rosenbergjennings-dispatch-ripp
VERSION = 00


all: $(DRAFT)-$(VERSION).txt $(DRAFT)-$(VERSION).html  ripp-api.html ripp-api.md 

diff: $(DRAFT).diff.html

clean:
	-rm -f $(DRAFT)-$(VERSION).{txt,html,xml,pdf} $(DRAFT).diff.html  ripp-api.{html,md}

.PHONY: all clean diff


ripp-api.md: ripp-api.raml 
	raml2html --theme raml2html-markdown-theme ripp-api.raml > ripp-api.md

ripp-api.html: ripp-api.raml 
	raml2html ripp-api.raml > ripp-api.html


.PRECIOUS: %.xml

%.html: %.xml
	xml2rfc --html $^ -o $@

%.txt: %.xml
	xml2rfc --text $^ -o $@

$(DRAFT)-$(VERSION).xml: $(DRAFT).md 
	mmark -xml2 -page $^ $@ 

$(DRAFT).diff.html: $(DRAFT)-$(VERSION).txt $(DRAFT)-old.txt 
	htmlwdiff   $(DRAFT)-old.txt   $(DRAFT)-$(VERSION).txt >   $(DRAFT).diff.html

