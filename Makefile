
output =  $(patsubst %.md,%.txt,$(wildcard draft*.md))  $(patsubst %.xml,%.txt,$(wildcard draft*.xml)) \
          $(patsubst %.md,%.html,$(wildcard draft*.md))  $(patsubst %.xml,%.html,$(wildcard draft*.xml))

all: $(output) all.tar ripp-api.md ripp-api.html seq-diagram.md

clean:
	-rm -f draft*.txt draft*.html ripp-api.{html,md} draft-rosenberg-dispatch-ript-sipdiffs.xml draft-rosenbergjennings-dispatch-ript.xml ripp-api.md ripp-api.html seq-diagram.md all.tar 

.PHONY: all clean 

.PRECIOUS: %.xml

%.html: %.xml
	xml2rfc --html $^ -o $@

%.txt: %.xml
	xml2rfc --text $^ -o $@

%.xml: %.md 
	mmark -xml2 -page $^ $@ 

all.tar: $(output)
	tar cvf all.tar $(output)

#$(DRAFT).diff.html: $(DRAFT)-$(VERSION).txt $(DRAFT).old
#	htmlwdiff   $(DRAFT).old $(DRAFT)-$(VERSION).txt > $(DRAFT).diff.html


ripp-api.md: ripp-api.raml 
	raml2html --theme raml2html-markdown-theme ripp-api.raml > ripp-api.md

ripp-api.html: ripp-api.raml 
	raml2html ripp-api.raml > ripp-api.html

seq-diagram.md: seq-diagram-out.txt
	echo "~~~ ascii-art" > seq-diagram.md
	cat seq-diagram-out.txt >> seq-diagram.md
	echo "~~~"  >> seq-diagram.md


