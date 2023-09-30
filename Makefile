include .env

ifeq ($(strip $(DOMAIN)),)
$(error DOMAIN must be specified in the .env file.)
endif

all: install

setup: objects/etc/ntfy/server.yml

objects/_temp_server.yml: templates/server.yml objects/
	sed \
	-e "s;\$${DOMAIN};$(DOMAIN);g" \
	$< > $@

objects/etc/ntfy/server.yml: objects/_temp_server.yml
	mkdir --parent $(dir $@)
	cp -f $< $@

clean:
	rm -rf objects

objects/:
	mkdir --parent objects

objects/install: templates/ntfy.nginx docker-compose.yml .env objects/
	sed \
	-e "s;$${DOMAIN};$(DOMAIN);g" \
	-e "s;$${SOCKET};$(dir $(abspath docker-compose.yml))/var/lib/ntfy/ntfy.sock" \
	$< > objects/_temp_test_config
	
	cp -f objects/_temp_test_config /etc/nginx/sites-enabled/$(DOMAIN)
	
	nginx -t
	systemctl restart nginx

	touch $@

objects/install_ssl: objects/install
	certbot --nginx -d $(DOMAIN) --redirect
	nginx -t
	systemctl restart nginx
	touch $@

install: objects/install

install_ssl: objects/install_ssl
