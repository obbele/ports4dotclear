SCRIPTS=../Scripts
DOC=$(wildcard *.mkd)
XHTML=$(DOC:.mkd=.xhtml)
DEBUG=debug.xhtml

all: $(XHTML) Media/text.mkd

Media/text.mkd: $(DOC)
	cd Media && \
	highlight -X -s zellner -S HTML -c ../highlight.css <../$^ >text.mkd

edit:
	$(EDITOR) $(DOC)

view: $(XHTML)
	xdg-open $^

debug: $(DOC)
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $^ |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w >$(DEBUG)

# CONFIG==XML-RPC config file
publish: $(XHTML)
	$(SCRIPTS)/publish.pl $(XHTML) $(CONFIG)

$(XHTML): $(DOC) Makefile
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $(DOC) |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w |\
		$(SCRIPTS)/FormatPRE.pl |\
		$(SCRIPTS)/NumberHeaders.pl |\
		$(SCRIPTS)/LowerHeaders.pl >$@

help:
	@echo "Usage:"
	@echo "	make [all]: only format document"
	@echo "	make view: format document and open with web browser"
	@echo "	make clean: remove all generated files"
	@echo "	make [CONFIG=foobar] publish: publish .xhtml"\
		    "document to a DotClear blog"
	@echo "	make debug: wrap HTML with headers and"\
		    "output the result in $(DEBUG)"
	@echo "	make edit: guess wha ?"
	@echo "	make help: display this help"

clean:
	-rm $(XHTML) $(DEBUG) highlight.css
	-rm Media/text.mkd

.PHONY: all view help publish debug
