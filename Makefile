on_wp_prod = ssh www-data@ssh-wwp.epfl.ch -p 32222

htaccesses.tar:
	 $(on_wp_prod) "find /srv '(' -name jahia2wp -o -name wp-content ')' -prune -false -o -name .htaccess | xargs tar cf -" > $@
