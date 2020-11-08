FROM eallion/ubuntu:openwrt
LABEL maintainer="eallion <eallions@gmail.com>"

VOLUME /root/openwrt/
WORKDIR /root/openwrt/

RUN \
    git clone https://github.com/coolsnowwolf/lede --depth=1 && \
    cd /root/openwrt/lede && \
    sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default && \
    sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a && \
    wget -c https://raw.githubusercontent.com/eallion/openwrt/main/.config

CMD ["/bin/bash"]