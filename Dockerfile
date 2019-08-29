FROM stefanfritsch/r_statup:3.5.3.20190829
LABEL maintainer="Stefan Fritsch <stefan.fritsch@stat-up.com>"

ENV RVERSION="3.5.3"
ENV RStudioVERSION="1.2.1335"

EXPOSE 8787
EXPOSE 3838

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
          gdebi-core \
          libclang-dev \
    && wget -q https://s3.amazonaws.com/rstudio-ide-build/server/trusty/amd64/rstudio-server-${RStudioVERSION}-amd64.deb \
    && dpkg -i rstudio-server-${RStudioVERSION}-amd64.deb \
    && rm rstudio-server-*-amd64.deb \   
    ## Symlink pandoc & standard pandoc templates for use system-wide
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
    && git clone https://github.com/jgm/pandoc-templates \
    && mkdir -p /opt/pandoc/templates \
    && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
    && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \    
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /etc/R \
    && echo '\n\
      \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
      \n# is not set since a redirect to localhost may not work depending upon \
      \n# where this Docker container is running. \
      \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
      \n  options(httr_oob_default = TRUE) \
      \n}' >> /opt/microsoft/ropen/${RVERSION}/lib64/R/etc/Rprofile.site \
    && echo "PATH=${PATH}" >> /opt/microsoft/ropen/${RVERSION}/lib64/R/etc/Renviron \
    ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
    &&  echo "rsession-which-r=/opt/microsoft/ropen/${RVERSION}/lib64/R/bin/R" >> /etc/rstudio/rserver.conf \
    ## use more robust file locking to avoid errors when using shared volumes:
    && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
    ## configure git not to request password each time
    && git config --system credential.helper 'cache --timeout=3600' \
    && git config --system push.default simple 

COPY rstudio.sh /etc/service/rstudio/run
RUN chmod +x /etc/service/rstudio/run
