SCRIPTS=../Scripts
DOC=$(wildcard *.mkd)
XHTML=$(DOC:.mkd=.xhtml)
TEST=test.xhtml

all: $(XHTML)

view: $(XHTML)
	xdg-open $^

test: $(DOC)
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $^ |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w >$(TEST)

# CONFIG==XML-RPC config file
publish: $(XHTML)
	$(SCRIPTS)/publish.pl $(XHTML) $(CONFIG)

$(XHTML): $(DOC) Makefile
	$(SCRIPTS)/Markdown_1.0.1/Markdown.pl $(DOC) |\
		$(SCRIPTS)/XML-RPC/dotclear.py -w |\
		$(SCRIPTS)/NumberHeaders.pl |\
		$(SCRIPTS)/FormatPRE.pl |\
		$(SCRIPTS)/LowerHeaders.pl >$@

help:
	@echo "Usage:"
	@echo "	make [all]: only format document"
	@echo "	make view: format document and open with web browser"
	@echo "	make clean: remove all generated files"
	@echo "	make [CONFIG=foobar] publish: publish .xhtml"\
		    "document to a DotClear blog"
	@echo "	make test: wrap HTML with headers and"\
		    "output the result in test.xhtml"
	@echo "	make help: display this help"

clean:
	-rm $(XHTML) $(TEST) highlight.css

.PHONY: all view help publish
