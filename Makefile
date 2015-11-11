SOURCES=$(wildcard src/*.coffee) $(wildcard src/*/*.coffee)
VIEWS=$(wildcard views/*.haml)

HTML_FILES=$(VIEWS:views/%.haml=out/%.html)

MAIN_SRC=src/main.coffee
BUNDLE=out/js/bomber.js
BUNDLE_MIN=out/js/bomber.min.js

all: browserify uglify haml

browserify: $(BUNDLE)

uglify: $(BUNDLE_MIN)

haml: $(HTML_FILES)

clean:
	rm -rf out/

$(BUNDLE): $(SOURCES) Makefile
	@mkdir -p `dirname $@`
	node_modules/.bin/browserify --extension=".coffee" -t coffeeify -t envify -s rtc-bomber -d $(MAIN_SRC) -o $@

out/%.html: views/%.haml Makefile
	@mkdir -p `dirname $@`
	node_modules/.bin/haml-coffee -r -i $< -o $(basename $@)

%.min.js: %.js Makefile
	node_modules/.bin/uglifyjs --compress --mangle -o $@ -- $<

