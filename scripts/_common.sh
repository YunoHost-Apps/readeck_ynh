#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Ensure CSP forwarding
# Cf. https://github.com/YunoHost/issues/issues/2301
# @TODO define `$CSP_fix_ynh_core_version` with the correct YNH 13.x version number that will include that fix https://github.com/YunoHost/yunohost/pull/2354.
fix_csp_forwarding() {
    CSP_fix_ynh_core_version="13.5.0" #version number formatted as such "13.0.6+202708201400", it works fine with additional subversion level and/or without the +{DATE} 
    current_ynh_core_version="$(yunohost --version | grep "yunohost:" --after-context 2 | tail -n 1 | sed -e 's/^\s*version: //')"
    if dpkg --compare-versions "$current_ynh_core_version" ge "CSP_fix_ynh_core_version" && grep -q '# Force usage of some app-defined headers' "/etc/nginx/conf.d/$domain/$app.conf"; then
        # Remove pre-Trixie fix from nginx.conf
	    sed -i '/\s*\# Force usage of/,/content_security_policy";/d' "/etc/nginx/conf.d/$domain/$app.conf"
	    ynh_systemctl --service=nginx --action=reload
    fi
    if dpkg --compare-versions "$current_ynh_core_version" lt "CSP_fix_ynh_core_version" && ! grep -q '# Force usage of some app-defined headers' "/etc/nginx/conf.d/$domain/$app.conf"; then
	    # Add pre-Trixie fix to nginx.conf
		sed -i '/\}/i \ \ # Force usage of some app-defined headers\
  # (fix for pre-YNH 13.x stable version, cf. https://github.com/YunoHost-Apps/readeck_ynh/issues/81)\
  more_set_headers "X-Frame-Options: $upstream_http_x_frame_options";\
  more_set_headers "Content-Security-Policy: $upstream_http_content_security_policy";'\
	    "/etc/nginx/conf.d/$domain/$app.conf"
        ynh_systemctl --service=nginx --action=reload
    fi
}
