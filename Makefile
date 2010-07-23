# Master Makefile
#
# managing the pool of messages by providing a set of global action
# (notably "make clean") and, for creating new messages, "make new"

# glob any folders looking like "01_foo", "33_bar" or "2738_none"
SUBDIRS = $(wildcard [0-9]*_*)
# Template for new message
TPL = Template

.PHONY: clean all view help new

help:
	@echo "Make targets:"
	@echo "	[help]: display this help"
	@echo "	clean : remove all generated files"
	@echo "	all   : format all documents"
	@echo "	new   : create a new directory based on $(TPL)/"
	@echo "	view  : open all documents within a web browser"
	@echo "	test  : try unit tests"
	@echo ""

all view clean:
	for dir in $(SUBDIRS);do\
		$(MAKE) -C $$dir $@;\
	done

test:
	$(MAKE) -C Tests test

# Simple copy and paste of $(TPL) directory
# if you want to play with hardlink, this is your chance
new:
	@read -p "Enter directory name: " && {\
		DIR="999_$$REPLY";\
		cp -r $(TPL) $$DIR;\
		echo "New directory created: [$$DIR]";\
	}
