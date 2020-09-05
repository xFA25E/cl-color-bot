SBCL ?= lisp
PACKAGE := color-bot

.PHONY: all build clean test run

all: clean build

run: | $(PACKAGE)
	./$(firstword $|)

build: $(PACKAGE)

clean:
	-rm $(PACKAGE)

test:
	echo dont know how to test yet

$(PACKAGE):
	$(SBCL) --eval '(ql:quickload :$@)' \
			--eval "(sb-ext:save-lisp-and-die \
					 \"$@\" :toplevel #'$@:main \
					 :executable t :purify t :compression 9)"
