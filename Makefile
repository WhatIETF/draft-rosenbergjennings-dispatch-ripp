#
# Makefile to build Internet Drafts from markdown using mmarc
#

SRC  := $(wildcard draft-*.md)
TXT  := $(patsubst %.md,%.txt,$(SRC))
HTML := $(patsubst %.md,%.html,$(SRC))

all: $(TXT) $(HTML)

clean:
	rm -f *~ draft*.txt draft-*.html draft-*.xml

%.html: %.xml
	xml2rfc --html $^ -o $@

%.txt: %.xml
	xml2rfc --text $^ -o $@

.PRECIOUS: %.xml
%.xml: %.md
	mmark -xml2 -page $^ $@ 
