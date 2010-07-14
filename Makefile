SUBDIRS = $(wildcard [0-9]*_*)
TPL = Template

.PHONY: clean all view help new

all view clean:
	for dir in $(SUBDIRS);do\
		$(MAKE) -C $$dir $@;\
	done

help:
	@echo "Usage:"
	@echo "	make [all]: only format documents"
	@echo "	make new: create a new directory based on Template/"
	@echo "	make clean: remove all generated files"
	@echo "	make view: format documents and open with web browser"
	@echo "	make help: display this help"

new:
	#Scripts/create_entry.pl
	read -p "Enter directory name: " && {\
		DIR="999_$$REPLY";\
		mkdir $$DIR;\
		cp $(TPL)/publish.log $$DIR/publish.log;\
		cp $(TPL)/text.mkd $$DIR/text.mkd;\
		ln $(TPL)/Makefile $$DIR/Makefile;\
		mkdir $$DIR/Media;\
		echo "New directory created: [$$DIR]";\
	}
