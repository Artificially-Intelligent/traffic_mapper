# Base image https://hub.docker.com/u/rocker/
ARG SRC_TAG=traffic_mapper
ARG SRC_IMAGE=artificiallyintelligent/shiny_lite
ARG $BLD_DATE
ARG $SRC_REPO
ARG $SRC_BRANCH
ARG $SRC_COMMIT
ARG $DEST_IMAGE

FROM $SRC_IMAGE:$SRC_TAG

ENV BUILD_DATE=$BLD_DATE
ENV SOURCE_DOCKER_IMAGE=$SRC_IMAGE:$SRC_TAG
ENV SOURCE_REPO=$SRC_REPO
ENV SOURCE_BRANCH=$SRC_BRANCH
ENV SOURCE_COMMIT=$SRC_COMMIT
ENV DOCKER_IMAGE=$DEST_IMAGE

## install package dependcies
ARG DISCOVERY=FALSE
ARG PROJECT_PACKAGES=config,shiny,shinycssloaders,shinyjs,shinyWidgets,stringr,scales,waiter,lubridate,dplyr,readxl,data.table,geojsonio,sf,RMySQL,DBI,pool,mongolite,here,ggplot2,ggiraph,ggiraphExtra,RColorBrewer,viridis,hrbrthemes,lattice,leaflet,OneR,shinycssloaders,shinydashboard,leaflet.extras,units,readxl,geojsonio,sf,RMySQL,sf,V8,DBI,pool,protolite,rgeos,jqr,RPostgres,janitor,RMariaDB,jsonify,plotly
ARG PROJECT_PACKAGES_PLUS=
ARG DEPENDENCY=

ENV DISCOVER_PACKAGES=$DISCOVERY
ENV REQUIRED_PACKAGES=$PROJECT_PACKAGES
ENV REQUIRED_PACKAGES_PLUS=$PROJECT_PACKAGES_PLUS
ENV DEPENDENCY_INSTALL=$DEPENDENCY

# ADD Rscripts/packages.csv ${SCRIPTS_DIR}/default_install_packages.csv
# ADD cont-init.d-defaults/install_discovered_packages.R ${SCRIPTS_DIR}/install_discovered_packages.R
# ADD cont-init.d-defaults/03_install_package_dependencies.sh  ${SCRIPTS_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh
# ADD cont-init.d-defaults/04_install_packages.sh  ${SCRIPTS_DIR}/cont-init.d-defaults/04_install_packages.sh

RUN chmod +x ${SCRIPTS_DIR}/cont-init.d-defaults/* \ 
	&& ${SCRIPTS_DIR}/cont-init.d-defaults/04_expand_packages_dependencies.sh \
	&& ${SCRIPTS_DIR}/cont-init.d-defaults/05_install_package_dependencies.sh \
	&& ${SCRIPTS_DIR}/cont-init.d-defaults/06_install_packages.sh

COPY Rscripts $WWW_DIR

RUN ${SCRIPTS_DIR}/cont-init.d-defaults/04_expand_packages_dependencies.sh \
	&& ${SCRIPTS_DIR}/cont-init.d-defaults/05_install_package_dependencies.sh \
	&& ${SCRIPTS_DIR}/cont-init.d-defaults/06_install_packages.sh

ENV INSTALL_PACKAGE_AT_RUNTIME=FALSE

## start shiny server
RUN ln -f ${SCRIPTS_DIR}/shiny-server.sh /usr/bin/shiny-server.sh \
	&& chmod +x /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]