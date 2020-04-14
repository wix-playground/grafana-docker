ARG GRAFANA_VERSION="6.7.2"

FROM grafana/grafana:${GRAFANA_VERSION}

USER root

ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="true"

ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"

RUN mkdir -p "$GF_PATHS_PLUGINS" && \
    chown -R grafana:grafana "$GF_PATHS_PLUGINS"

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

ARG GF_INSTALL_PLUGINS="ayoungprogrammer-finance-datasource,blackmirror1-statusbygroup-panel,briangann-datatable-panel,btplc-trend-box-panel,doitintl-bigquery-datasource,grafana-clock-panel,grafana-image-renderer,grafana-piechart-panel,grafana-polystat-panel,grafana-simple-json-datasource,jdbranham-diagram-panel,natel-discrete-panel,natel-plotly-panel,petrslavotinek-carpetplot-panel,raintank-worldping-app,ryantxu-ajax-panel,vertamedia-clickhouse-datasource,vonage-status-panel"

RUN if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then \
    OLDIFS=$IFS; \
        IFS=','; \
    for plugin in ${GF_INSTALL_PLUGINS}; do \
        IFS=$OLDIFS; \
        grafana-cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install ${plugin}; \
    done; \
fi