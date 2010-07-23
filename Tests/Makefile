TESTS = $(wildcard *.l.t)

.PHONY: test force help

test:
	perl harness.pl

force:
	for t in $(TESTS);do\
		echo "[$$t]";\
		perl $$t;\
		echo;\
	done

help:
	@echo "make help   : display this message"
	@echo "make [test] : run all tests, stopping if any errors are spotted"
	@echo "make force  : run all tests, would they fail or naugh"
