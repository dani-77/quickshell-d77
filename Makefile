PREFIX := /usr
SHAREDIR := $(PREFIX)/share/quickshell/quickshell-d77

.PHONY: install uninstall

install:
	install -d $(DESTDIR)$(SHAREDIR)
	rsync -a --delete \
		--exclude='.git' \
		--exclude='.claude' \
		--exclude='Makefile' \
		./ $(DESTDIR)$(SHAREDIR)/

uninstall:
	rm -rf $(DESTDIR)$(SHAREDIR)
