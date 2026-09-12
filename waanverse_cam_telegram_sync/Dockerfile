FROM ghcr.io/hassio-addons/base:14.0.0
RUN apk add --no-cache ffmpeg jq curl
COPY run.sh /run.sh
RUN chmod a+x /run.sh
CMD ["/run.sh"]