# R Markdown files.
SRC_RMD = $(wildcard ??-*.Rmd)
DST_RMD = $(patsubst %.Rmd,%.md,$(SRC_RMD))

# All Markdown files (hand-written and generated).
ALL_MD = $(wildcard *.md) $(DST_RMD)
EXCLUDE_MD = README.md LAYOUT.md FAQ.md DESIGN.md CONTRIBUTING.md CONDUCT.md
SRC_MD = $(filter-out $(EXCLUDE_MD),$(ALL_MD))
DST_HTML = $(patsubst %.md,_site/%.html,$(SRC_MD))
DST_ASSETS = img js data code css

# All outputs.
DST_ALL = $(DST_HTML) $(patsubst %,_site/%,$(DST_ASSETS))

# Pandoc filters.
FILTERS = $(wildcard tools/filters/*.py)

# Inclusions.
INCLUDES = \
	-Vheader="$$(cat _includes/header.html)" \
	-Vbanner="$$(cat _includes/banner.html)" \
	-Vfooter="$$(cat _includes/footer.html)" \
	-Vjavascript="$$(cat _includes/javascript.html)"

# Chunk options for knitr (used in R conversion).
R_CHUNK_OPTS = tools/chunk-options.R

# Ensure that intermediate (generated) Markdown files from R are kept.
.SECONDARY: $(DST_RMD)

# Default action is to show what commands are available.
all : commands

## check    : Validate all lesson content against the template.
check: $(ALL_MD)
	python tools/check.py .
	pep8 code

## clean    : Clean up temporary and intermediate files.
clean :
	@rm -rf $$(find . -name '*~' -print)
	rm -rf ./_site

## preview  : Build website locally for checking.
preview : $(DST_ALL)

# Pattern for slides (different parameters and template).
motivation.html : motivation.md _layouts/slides.revealjs Makefile
	pandoc -s -t revealjs --slide-level 2 \
	--template=_layouts/slides \
	-o $@ $<

# Pattern to build a generic page.
_site/%.html : %.md _layouts/page.html $(FILTERS) | _site
	# The --mathjax flag will change $ and $$ to \(\) and \[\],
	# which our KaTeX installation will auto-convert to LaTeX
	pandoc -s -t html \
	--template=_layouts/page \
	--filter=tools/filters/blockquote2div.py \
	--filter=tools/filters/id4glossary.py \
	--mathjax \
	$(INCLUDES) \
	-o $@ $<

_site/%: % | _site
	cp -r $< $@

_site:
	mkdir -p _site

# Pattern to convert R Markdown to Markdown.
%.md: %.Rmd $(R_CHUNK_OPTS)
	Rscript -e "knitr::knit('$$(basename $<)', output = '$$(basename $@)')"

## commands : Display available commands.
commands : Makefile
	@sed -n 's/^##//p' $<

## settings : Show variables and settings.
settings :
	@echo 'SRC_RMD:' $(SRC_RMD)
	@echo 'DST_RMD:' $(DST_RMD)
	@echo 'SRC_MD:' $(SRC_MD)
	@echo 'DST_HTML:' $(DST_HTML)

## unittest : Run internal tests to ensure the validator is working correctly (for Python 2 and 3).
unittest: tools/check.py tools/validation_helpers.py tools/test_check.py
	cd tools/ && python2 test_check.py
	cd tools/ && python3 test_check.py

publish-travis: preview
	@ghp-import -n ./_site && git push -fq https://${GH_TOKEN}@github.com/$(TRAVIS_REPO_SLUG).git gh-pages > /dev/null

