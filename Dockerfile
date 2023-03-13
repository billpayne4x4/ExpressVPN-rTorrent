FROM debian:bookworm-slim

ENV CODE="code"
ENV SERVER="samrt"
ENV PROTOCOL="lightway_udp"
ENV CIPHER="chacha20"

ARG NUM
ARG PLATFORM
RUN useradd -ms /bin/bash rtorrent
RUN echo 'rtorrent:password' | chpasswd
COPY scripts/ /expressvpn/
COPY files/.rtorrent.rc /home/rtorrent
RUN chown rtorrent:rtorrent /home/rtorrent/.rtorrent.rc
RUN echo 'deb http://deb.debian.org/debian/ bookworm universe' >> /etc/apt/sources.list.d/debian.sources
RUN echo 'deb-src http://deb.debian.org/debian/ bookworm universe' >> /etc/apt/sources.list.d/debian.sources

# Install packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends expect curl \
    ca-certificates iproute2 wget jq iputils-ping rtorrent \
    git build-essential nodejs npm lighttpd php-fpm php \
    mediainfo unzip php-cgi nano net-tools sox ffmpeg pipx

# Install ExpressVPN
RUN wget -q https://www.expressvpn.works/clients/linux/expressvpn_${NUM}-1_${PLATFORM}.deb -O /expressvpn/expressvpn_${NUM}-1_${PLATFORM}.deb
RUN dpkg -i /expressvpn/expressvpn_${NUM}-1_${PLATFORM}.deb

# Install rar and unrar
RUN wget https://www.rarlab.com/rar/rarlinux-x64-621.tar.gz
RUN tar -xvf rar*.tar.gz
RUN cp /rar/rar /usr/bin/
RUN cp /rar/unrar /usr/bin/

# Create python link
RUN ln -s /usr/bin/python3 /usr/bin/python

# Create directory for rtorrent session
RUN mkdir /home/rtorrent/session
RUN chown rtorrent:rtorrent /home/rtorrent/session

# Install rutorrent
RUN git clone https://github.com/Novik/ruTorrent.git /var/www/html/rutorrent/
RUN git clone https://github.com/Micdu70/QuickBox-Dark.git /var/www/html/rutorrent/plugins/theme/themes/QuickBox-Dark
RUN chown -R www-data:www-data /var/www/html/rutorrent
RUN chmod 777 /var/www/html/rutorrent/share/torrents
RUN chmod 777 /var/www/html/rutorrent/share/settings

# Setup lighttpd
RUN echo 'server.modules += ("mod_fastcgi", "mod_access", "mod_alias", "mod_compress", "mod_redirect", "mod_scgi")' >> /etc/lighttpd/lighttpd.conf
RUN echo 'scgi.server = ("/RPC2" => ( "127.0.0.1" => ("host" => "127.0.0.1", "port" => 5000, "check-local" => "disable")))' >> /etc/lighttpd/lighttpd.conf
RUN echo 'fastcgi.server = ( ".php" => (("bin-path" => "/usr/bin/php-cgi", "socket" => "/tmp/php.socket")))' >> /etc/lighttpd/lighttpd.conf
RUN sed -i 's|"/var/www/html"|"/var/www/html/rutorrent"|g' /etc/lighttpd/lighttpd.conf
RUN sed -i 's/80/3000/' /etc/lighttpd/lighttpd.conf

# Hack to install cloudscraper python module
RUN pipx install cloudscraper --include-deps
RUN cp -r /root/.local/pipx/venvs/cloudscraper /usr/local/lib/python*/dist-packages/

# Cleanup
RUN rm -rf /rar
RUN rm -rf /expressvpn/*.deb
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get purge --autoremove -y wget
RUN rm -rf /var/log/*.log


EXPOSE 3000
EXPOSE 5000

ENTRYPOINT ["/bin/bash", "/expressvpn/start.sh"]