.PHONY: prepack, pack, pack-data, pack-code, post, clean, distclean, doc

# install markdown and python-markdown-math
# pip install --user markdown
# pip install --user python-markdown-math

CURRENT_MAKEFILE_LIST := $(MAKEFILE_LIST)
MDIR := $(dir $(lastword $(CURRENT_MAKEFILE_LIST)))
$(warning $(MAKEFILE_LIST))

pack-all: pack-data pack-code pack
doc: doc/instructions.html

tarflags=--exclude='.git*'

DST := vgg@login.robots.ox.ac.uk:WWW/share
DSTDOC := vgg@login.robots.ox.ac.uk:WWW/practicals/$(name)

code:=$(addprefix $(CURDIR)/,$(code))
data:=$(addprefix $(CURDIR)/,$(data))
doc:=$(addprefix $(CURDIR)/,$(doc))
deps:=$(shell find $(code) $(doc) $(data) -type f | sed "s/ /\\\\ /g")

pack: $(TMPDIR)/$(name).tar.gz
pack-data: $(TMPDIR)/$(name)-data-only.tar.gz
pack-code: $(TMPDIR)/$(name)-code-only.tar.gz

$(TMPDIR)/$(name).tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(name)
	mkdir -p $(TMPDIR)/$(name)/{doc,data}
	ln -sf $(data) $(TMPDIR)/$(name)/data/
	ln -sf $(doc) $(TMPDIR)/$(name)/doc/
	ln -sf $(code) $(TMPDIR)/$(name)/
	tar -C $(TMPDIR) -czvhf $(TMPDIR)/$(name).tar.gz $(tarflags) $(name)/

$(TMPDIR)/$(name)-data-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(name)
	mkdir -p $(TMPDIR)/$(name)/{doc,data}
	ln -sf $(data) $(TMPDIR)/$(name)/
	tar -C $(TMPDIR) -czvhf $(TMPDIR)/$(name)-data-only.tar.gz $(tarflags) $(name)/

$(TMPDIR)/$(name)-code-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(name)
	mkdir -p $(TMPDIR)/$(name)/{doc,data}
	ln -sf $(doc) $(TMPDIR)/$(name)/doc/
	ln -sf $(code) $(TMPDIR)/$(name)/
	tar -C $(TMPDIR) -czvhf $(TMPDIR)/$(name)-code-only.tar.gz $(tarflags) $(name)/

doc/instructions.html : doc/instructions.md doc/base.css doc/prism.js doc/prism.css $(MDIR)/base.html $(MDIR)/end.html $(MDIR)/Makefile
	(cat "$(MDIR)/base.html" ; \
	python -m markdown \
	  -x toc -x footnotes -x tables -x fenced_code -x attr_list -x mdx_math \
	  "$<" ; \
	cat "$(MDIR)/end.html") > "$@"

doc/%: $(MDIR)/%
	cp -f "$(<)" "$(@)"

post-doc: doc
	rsync -rvt doc/images "$(DSTDOC)/"
	rsync -vt doc/instructions.html "$(DSTDOC)/index.html"

post: pack-all
	rsync -vt "$(TMPDIR)/$(name).tar.gz" "$(DST)/"
	rsync -vt "$(TMPDIR)/$(name)-data-only.tar.gz" "$(DST)/"
	rsync -vt "$(TMPDIR)/$(name)-code-only.tar.gz" "$(DST)/"

clean:
	find . -name '*~' -delete

distclean: clean
	rm -f $(TMPDIR)/$(name)*.tar.gz
