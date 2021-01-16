project_name = remarkable-lcars
config_path = /opt/etc/$(project_name).conf

install:
	# Copy files to where they belong
	cp $(project_name).sh /opt/bin/$(project_name)
	dos2unix /opt/bin/$(project_name)
	mkdir -p /opt/share/$(project_name)
	cp -r assets/* /opt/share/$(project_name)/
	cp systemd/*.* /etc/systemd/system
	dos2unix /etc/systemd/system/$(project_name).*
	test ! -f $(config_path) && cp $(project_name).conf $(config_path) || true
	dos2unix $(config_path)
	systemctl daemon-reload

package:
	echo "Not yet implemented"
