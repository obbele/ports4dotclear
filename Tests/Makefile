TESTS = $(wildcard *.l.t)

.PHONY: test force help
test: $(TESTS)

FORCE:

%.l.t: FORCE
	@echo "[$@]"
	@perl $@
	@echo

force:
	for t in $(TESTS);do\
		echo "[$$t]";\
		perl $$t;\
		echo;\
	done

help:
	@echo "make help  : display this message"
	@echo "make [all] : run all tests, stopping if any errors are spotted"
	@echo "make force : run all tests, would they fail or naugh"
