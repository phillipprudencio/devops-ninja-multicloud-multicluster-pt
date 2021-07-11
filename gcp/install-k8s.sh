#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh
apt install -y open-iscsi
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.8 --server https://18.217.196.140 --token 4vnjj6ffnxjgzhffrxglcpgwttphtjnmdjw84jn8gzrv5cxjsqklg7 --ca-checksum f0fd372a18980bedbaa0dc15997737d096180929006e2a31e02231b2b2d62ea5 --etcd --controlplane --worker