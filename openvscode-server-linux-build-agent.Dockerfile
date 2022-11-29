FROM ubuntu:18.04

CMD ["bash"]
ARG DEBIAN_FRONTEND=noninteractive

RUN export DEBIAN_FRONTEND=noninteractive && groupadd --gid 1000 builduser  \
	&& useradd --uid 1000 --gid builduser --shell /bin/bash --create-home builduser  \
	&& mkdir -p /setup

ENV TEMP=/tmp

RUN export DEBIAN_FRONTEND=noninteractive && chmod a+rwx /tmp

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update  \
	&& apt-get install -y software-properties-common

RUN export DEBIAN_FRONTEND=noninteractive && add-apt-repository ppa:git-core/ppa -y

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update  \
	&& apt-get install -y apt-transport-https ca-certificates curl git gnome-keyring iproute2 libfuse2 libgconf-2-4 libgdk-pixbuf2.0-0 libgl1 libgtk-3.0 libsecret-1-dev libssl-dev libx11-dev libx11-xcb-dev libxkbfile-dev locales lsb-release lsof python-dbus python-pip sudo wget xvfb tzdata unzip jq  \
	&& curl https://chromium.googlesource.com/chromium/src/+/HEAD/build/install-build-deps.sh\?format\=TEXT | base64 --decode | cat > /setup/install-build-deps.sh  \
	&& chmod +x /setup/install-build-deps.sh  \
	&& bash /setup/install-build-deps.sh --syms --no-prompt --no-chromeos-fonts --no-arm --no-nacl  \
	&& rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -

RUN export DEBIAN_FRONTEND=noninteractive && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update  \
	&& apt-get install -y yarn

RUN export DEBIAN_FRONTEND=noninteractive && echo 'builduser ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-builduser  \
	&& echo 'Defaults env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

RUN export DEBIAN_FRONTEND=noninteractive && wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

RUN export DEBIAN_FRONTEND=noninteractive && dpkg -i packages-microsoft-prod.deb

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update  \
	&& apt-get install -y dotnet-sdk-2.1

RUN export DEBIAN_FRONTEND=noninteractive && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN export DEBIAN_FRONTEND=noninteractive && python --version

RUN export DEBIAN_FRONTEND=noninteractive && sudo mkdir -p /var/run/dbus

RUN export DEBIAN_FRONTEND=noninteractive && gcc --version

RUN export DEBIAN_FRONTEND=noninteractive && g++ --version D
