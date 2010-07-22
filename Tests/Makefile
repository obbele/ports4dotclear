TESTS = $(wildcard *.l.t)

.PHONY: test
test:
	for t in $(TESTS);do\
		perl $$t;\
	done
