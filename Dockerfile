FROM rhub/r-minimal

RUN installr -d \
   -t "R-dev file automake autoconf linux-headers" \
   -a "libxml2-dev icu-libs" \
   tidyverse/readxl `# CRAN version does not compile on alpine` \
   tidyverse \
   shiny

COPY --from=node:13.10.1-alpine /usr/local/bin/node /usr/local/bin
COPY --from=node:13.10.1-alpine /usr/local/lib /usr/local/lib
# spatial


RUN echo "@edgemain http://dl-cdn.alpinelinux.org/alpine/v3.11/main" >> /etc/apk/repositories
RUN echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/v3.11/community" >> /etc/apk/repositories


RUN apk add poppler@edgemain 
RUN apk add proj-dev@edgecommunity gdal-dev@edgecommunity

#RUN apk add --no-cache -t .DEV R-dev && \
#    apk del .DEV

# shiny server
RUN apk add --no-cache -t .DEV cmake g++ gcc python2 git && \
    git clone https://github.com/rstudio/shiny-server.git && \
    cd shiny-server && mkdir tmp && cd tmp && \
    DIR=`pwd` && PATH=$DIR/../bin:$PATH && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ && \
    make && mkdir ../build && \
    echo $PWD && \
    (cd .. && mkdir -p ext/node) && \
    (cd ../ext/node && cp -r /usr/local/bin .) && \
    (cd ../ext/node && cp -r /usr/local/lib .) && \
    (cd .. && ./bin/npm --python="/usr/bin/python" --unsafe-perm install) && \
    (cd .. && ./bin/node /usr/local/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js --python="/usr/bin/python" rebuild) && \
    make install  && \
    apk del .DEV

RUN ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server && \
    addgroup -g 82 -S shiny; \
    adduser -u 82 -D -S -G shiny shiny && \
    mkdir -p /srv/shiny-server && \
    mkdir -p /var/lib/shiny-server && \
    mkdir -p /etc/shiny-server 

#RUN apk add bash
    
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY shiny-server.sh /usr/bin/shiny-server.sh

# fix su --login on alpine
RUN sed -i s/\-\-login/\-/ /usr/local/shiny-server/lib/worker/app-worker.js
RUN sed -i 's/\/bash/\/sh/' /usr/local/shiny-server/lib/worker/app-worker.js

# Move sample apps to test installation, clean up
RUN chmod 744 /usr/bin/shiny-server.sh && \
    mv /shiny-server/samples/sample-apps /srv/shiny-server/ && \
    mv /shiny-server/samples/welcome.html /srv/shiny-server/ && \
    rm -rf /shiny-server/

WORKDIR /srv/shiny-server

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]

