.PHONY: prepack, pack, pack-data, pack-code, post, clean, distclean, doc

# install markdown and python-markdown-math
# pip install --user markdown
# pip install --user python-markdown-math

SHELL := /bin/bash
CURRENT_MAKEFILE_LIST := $(MAKEFILE_LIST)
MDIR := $(dir $(lastword $(CURRENT_MAKEFILE_LIST)))
$(warning $(MAKEFILE_LIST))

pack-all: pack-data pack-code pack
doc: doc/instructions.html

tarflags=--exclude='.git*' --exclude='.build' --exclude='local' --exclude='*~'

DST := vgg@login.robots.ox.ac.uk:WWW/share
DSTDOC := vgg@login.robots.ox.ac.uk:WWW/practicals/$(subst practical-,,$(name))
TMPDIR := /tmp

distname:=$(name)-$(ver)
code:=$(addprefix $(CURDIR)/,$(code))
data:=$(addprefix $(CURDIR)/,$(data))
doc:=$(addprefix $(CURDIR)/,$(doc))
deps:=$(shell find $(code) $(doc) $(data) -type f | sed "s/ /\\\\ /g")

pack: $(TMPDIR)/$(distname).tar.gz
pack-data: $(TMPDIR)/$(distname)-data-only.tar.gz
pack-code: $(TMPDIR)/$(distname)-code-only.tar.gz

$(TMPDIR)/$(distname).tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/{doc,data}
	ln -sf $(data) $(TMPDIR)/$(distname)/data/
	ln -sf $(doc) $(TMPDIR)/$(distname)/doc/
	ln -sf $(code) $(TMPDIR)/$(distname)/
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname).tar.gz

$(TMPDIR)/$(distname)-data-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/{doc,data}
	ln -sf $(data) $(TMPDIR)/$(distname)/data/
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname)-data-only.tar.gz 

$(TMPDIR)/$(distname)-code-only.tar.gz: $(deps)
	rm -rf $(TMPDIR)/$(distname)
	mkdir -p $(TMPDIR)/$(distname)/{doc,data}
	ln -sf $(doc) $(TMPDIR)/$(distname)/doc/
	ln -sf $(code) $(TMPDIR)/$(distname)/
	tar -C $(TMPDIR) -cvh $(tarflags) $(distname)/ | gzip -n >$(TMPDIR)/$(distname)-code-only.tar.gz

doc/instructions.html : doc/instructions.md doc/base.css doc/prism.js doc/prism.css $(MDIR)/base.html $(MDIR)/end.html $(MDIR)/Makefile
	(cat "$(MDIR)/base.html" ; \
	python -m markdown \
	  -x toc -x footnotes -x tables -x fenced_code -x attr_list -x mathjax \
	  -c "$(MDIR)/markdown-config.json" \
	  "$<" ; \
	cat "$(MDIR)/end.html") > "$@"

doc/%: $(MDIR)/%
	cp -f "$(<)" "$(@)"

post-doc: doc
	rsync -rvt doc/images doc/base.css doc/prism.css doc/prism.js "$(DSTDOC)/"
	rsync -vt doc/instructions.html "$(DSTDOC)/index.html"

post: pack-all
	rsync -vt "$(TMPDIR)/$(distname).tar.gz" "$(DST)/"
	rsync -vt "$(TMPDIR)/$(distname)-data-only.tar.gz" "$(DST)/"
	rsync -vt "$(TMPDIR)/$(distname)-code-only.tar.gz" "$(DST)/"

clean:
	find . -name '*~' -delete

distclean: clean
	rm -f $(TMPDIR)/$(distname)*.tar.gz
	rm -rf $(TMPDIR)/$(distname)/

info: info-dist

info-dist:
	@echo "name = $(name)"
	@echo "ver = $(ver)"
	@echo "distname = $(distname)"
	@echo "TMPDIR = $(TMPDIR)"
