SOURCES=$(wildcard src/*.coffee) $(wildcard src/*/*.coffee)
VIEWS=$(wildcard views/*.haml)

HTML_FILES=$(VIEWS:views/%.haml=out/%.html)

MAIN_SRC=src/main.cjsx
BUNDLE=out/js/bomber.js
BUNDLE_MIN=out/js/bomber.min.js

all: browserify uglify haml

init: node_modules

node_modules: package.json
	npm install
	touch node_modules

browserify: $(BUNDLE)

uglify: $(BUNDLE_MIN)

haml: $(HTML_FILES)

clean:
	rm -rf out/

$(BUNDLE): $(SOURCES) Makefile init
	@mkdir -p `dirname $@`
	node_modules/.bin/browserify --extension=".coffee" --extension=".cjsx" -t cjsxify -t envify -s rtc-bomber -d $(MAIN_SRC) -o $@

out/%.html: views/%.haml Makefile init
	@mkdir -p `dirname $@`
	node_modules/.bin/haml-coffee -r -i $< -o $(basename $@)

%.min.js: %.js Makefile init
	node_modules/.bin/uglifyjs --compress --mangle -o $@ -- $<

