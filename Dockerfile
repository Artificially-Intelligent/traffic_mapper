# Base image https://hub.docker.com/u/rocker/
ARG SOURCE_TAG=3.6.3
ARG SOURCE_IMAGE=artificiallyintelligent/shiny_heavy
FROM $SOURCE_IMAGE:$SOURCE_TAG

ARG $SOURCE_REPO
ARG $SOURCE_BRANCH
ARG $SOURCE_COMMIT

ENV SOURCE_DOCKER_IMAGE=$SOURCE_IMAGE:$SOURCE_TAG
ENV SOURCE_REPO=$SOURCE_REPO
ENV SOURCE_BRANCH=$SOURCE_BRANCH
ENV SOURCE_COMMIT=$SOURCE_COMMIT

## install package dependcies
ARG DISCOVER_PACKAGES=TRUE
ARG REQUIRED_PACKAGES=
ARG REQUIRED_PACKAGES_PLUS=config,shiny,shinycssloaders,shinyjs,shinyWidgets,stringr,scales,waiter,dplyr,readxl,data.table,geojsonio,sf,RMySQL,DBI,pool,mongolite,here,ggplot2,ggiraph,ggiraphExtra,RColorBrewer,viridis,hrbrthemes,lattice,leaflet
ARG DEPENDENCY_INSTALL=

ENV DISCOVER_PACKAGES ${DISCOVER_PACKAGES}
ENV REQUIRED_PACKAGES ${REQUIRED_PACKAGES}
ENV REQUIRED_PACKAGES_PLUS ${REQUIRED_PACKAGES_PLUS}
ENV DEPENDENCY_INSTALL ${DEPENDENCY_INSTALL}

COPY Rscripts $WWW_DIR
ADD Rscripts/packages.csv ${LIB_DIR}/default_install_packages.csv
# ADD cont-init.d-defaults/03_install_package_dependencies.sh  ${LIB_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh
ADD cont-init.d-defaults/04_install_packages.sh  ${LIB_DIR}/cont-init.d-defaults/04_install_packages.sh
# ADD cont-init.d-defaults/06_copy_configxml_to_shiny_root.sh  ${LIB_DIR}/cont-init.d-defaults/06_copy_configxml_to_shiny_root.sh

RUN chmod +x ${LIB_DIR}/cont-init.d-defaults/* \ 
	&& ${LIB_DIR}/cont-init.d-defaults/03_install_package_dependencies.sh \
	&& ${LIB_DIR}/cont-init.d-defaults/04_install_packages.sh \ 
	$$ rm 

## start shiny server
RUN ln -f ${LIB_DIR}/shiny-server.sh /usr/bin/shiny-server.sh \
	&& chmod +x /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]