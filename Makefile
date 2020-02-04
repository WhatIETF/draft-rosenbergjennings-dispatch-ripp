# Makefile to build Internet Drafts from markdown using mmarc


DRAFT = draft-rosenbergjennings-dispatch-ripp
VERSION = 04


all: draft-rosenberg-dispatch-ripp-chat.txt draft-rosenberg-dispatch-ripp-inbound.txt draft-rosenberg-dispatch-ripp-phone-features.txt draft-rosenberg-dispatch-ripp-webrtc.txt $(DRAFT)-$(VERSION).txt  $(DRAFT)-$(VERSION).html ripp-api.html ripp-api.md draft-rosenberg-dispatch-ripp-sipdiffs.xml

diff: $(DRAFT).diff.html

clean:
	-rm -f $(DRAFT)-$(VERSION).{txt,html,xml,pdf} $(DRAFT).diff.html  draft*.txt ripp-api.{html,md}

.PHONY: all clean diff


ripp-api.md: ripp-api.raml 
	raml2html --theme raml2html-markdown-theme ripp-api.raml > ripp-api.md

ripp-api.html: ripp-api.raml 
	raml2html ripp-api.raml > ripp-api.html

seq-diagram.md: seq-diagram-out.txt
	echo "~~~ ascii-art" > seq-diagram.md
	cat seq-diagram-out.txt >> seq-diagram.md
	echo "~~~"  >> seq-diagram.md

.PRECIOUS: %.xml

%.html: %.xml
	xml2rfc --html $^ -o $@

%.txt: %.xml
	xml2rfc --text $^ -o $@

$(DRAFT)-$(VERSION).xml: $(DRAFT).md  seq-diagram.md  ripp-api.md
	mmark -xml2 -page $(DRAFT).md $@ 

$(DRAFT).diff.html: $(DRAFT)-$(VERSION).txt $(DRAFT)-old.txt 
	htmlwdiff   $(DRAFT)-old.txt   $(DRAFT)-$(VERSION).txt >   $(DRAFT).diff.html


draft-rosenberg-dispatch-ripp-sipdiffs.xml: draft-rosenberg-dispatch-ripp-sipdiffs.md
	mmark -xml2 -page $(DRAFT).md $@ 
