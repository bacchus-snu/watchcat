all:
	true

install:
	mkdir -p $(DESTDIR)/opt
	cp -r watchcat-client $(DESTDIR)/opt
	mkdir -p $(DESTDIR)/usr/lib/systemd/system
	cp -rT systemd $(DESTDIR)/usr/lib/systemd/system
