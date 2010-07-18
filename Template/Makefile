SCRIPTS=../Scripts
DOC=$(wildcard *.mkd)
XHTML=$(DOC:.mkd=.xhtml)
DEBUG=debug.xhtml

all: $(XHTML)

edit:
	$(EDITOR) $(DOC)

view: all
	xdg-open $(XHTML)

debug: $(DOC)
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $^ |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w >$(DEBUG)

# CONFIG==XML-RPC config file
publish: $(XHTML)
	$(SCRIPTS)/publish.pl $(XHTML) $(CONFIG)

highlight.css:
	highlight -X --print-style -c highlight.css

$(XHTML): $(DOC) Makefile highlight.css
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $(DOC) |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w |\
		$(SCRIPTS)/Externalize.pl |\
		$(SCRIPTS)/NumberHeaders.pl |\
		$(SCRIPTS)/LowerHeaders.pl >$@

help:
	@echo "Usage:"
	@echo "	make [all]: only format the document"
	@echo "	make view: format the document and open it with a web browser"
	@echo "	make clean: remove all generated files"
	@echo "	make [CONFIG=foobar] publish: publish *.xhtml to a DotClear blog"
	@echo "	make debug: wrap HTML with headers and output the result in $(DEBUG)"
	@echo "	make edit: guess what ?"
	@echo "	make help: display this help"

clean:
	-rm $(XHTML) $(DEBUG) highlight.css

.PHONY: all view help publish debug
