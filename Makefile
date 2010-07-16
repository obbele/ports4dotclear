SUBDIRS = $(wildcard [0-9]*_*)
TPL = Template

.PHONY: clean all view help new

all view clean:
	for dir in $(SUBDIRS);do\
		$(MAKE) -C $$dir $@;\
	done

help:
	@echo "Usage:"
	@echo "	make [all]: format all documents"
	@echo "	make new: create a new directory based on Template/"
	@echo "	make clean: remove all generated files"
	@echo "	make view: open all documents within a web browser"
	@echo "	make help: display this help"

new:
	@read -p "Enter directory name: " && {\
		DIR="999_$$REPLY";\
		mkdir $$DIR;\
		cd $$DIR;\
		cp ../$(TPL)/publish.log publish.log;\
		cp ../$(TPL)/text.mkd text.mkd;\
		ln -s ../$(TPL)/Makefile Makefile;\
		mkdir Media;\
		cd ..;\
		echo "New directory created: [$$DIR]";\
	}
