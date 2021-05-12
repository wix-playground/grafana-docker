ARG GRAFANA_VERSION="7.5.6"

FROM grafana/grafana:${GRAFANA_VERSION}

USER root

ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="true"

# TINI is added this way (and not with --init falg) because we use chef to provision
# our docker cookbook is forked by forket 5 years ago and that version doesn't support --init flag
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--", "/run.sh"]


ARG GF_GID="0"
ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"

RUN mkdir -p "$GF_PATHS_PLUGINS" && \
    chown -R grafana:${GF_GID} "$GF_PATHS_PLUGINS"
    
RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --no-cache  upgrade && \
    apk add --no-cache udev ttf-opensans chromium && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/grafana/tools/phantomjs; \
fi

USER grafana

ENV GF_RENDERER_PLUGIN_CHROME_BIN="/usr/bin/chromium-browser"

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    grafana-cli \
        --pluginsDir "$GF_PATHS_PLUGINS" \
        --pluginUrl https://github.com/grafana/grafana-image-renderer/releases/latest/download/plugin-linux-x64-glibc-no-chromium.zip \
        plugins install grafana-image-renderer; \
fi

ARG GF_INSTALL_PLUGINS="ayoungprogrammer-finance-datasource,blackmirror1-statusbygroup-panel,briangann-datatable-panel,btplc-trend-box-panel,doitintl-bigquery-datasource,grafana-clock-panel,grafana-image-renderer,grafana-piechart-panel,grafana-polystat-panel,grafana-simple-json-datasource,jdbranham-diagram-panel,natel-discrete-panel,natel-plotly-panel,petrslavotinek-carpetplot-panel,raintank-worldping-app,ryantxu-ajax-panel,vonage-status-panel,grafana-synthetic-monitoring-app,yesoreyeram-boomtable-panel"

RUN if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then \
    OLDIFS=$IFS; \
        IFS=','; \
    for plugin in ${GF_INSTALL_PLUGINS}; do \
        IFS=$OLDIFS; \
        grafana-cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install ${plugin}; \
    done; \
fi

RUN grafana-cli --pluginUrl https://github.com/mikhno-s/clickhouse-grafana/archive/master.zip plugins install vertamedia-clickhouse-datasource

RUN grafana-cli --pluginUrl https://github.com/yesoreyeram/yesoreyeram-boomtable-panel/releases/download/v1.5.0-alpha.3/yesoreyeram-boomtable-panel-1.5.0-alpha.3.zip  plugins install yesoreyeram-boomtable-panel