FROM ruotiantang/openvscode-server-linux-build-agent:bionic-x64 as code_builder

ARG NODE_VERSION=16.16.0
ARG NVM_DIR="/root/.nvm"
RUN mkdir -p $NVM_DIR \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | sh \
    && . $NVM_DIR/nvm.sh \
    && nvm alias default $NODE_VERSION
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1

RUN mkdir /devopsRemoting-code \
	&& cd /devopsRemoting-code

COPY . /devopsRemoting-code/

WORKDIR /devopsRemoting-code
ENV npm_config_arch=x64
RUN yarn --frozen-lockfile --network-timeout 180000

# update product.json
RUN nameShort=$(jq --raw-output '.nameShort' product.json) && \
	nameLong=$(jq --raw-output '.nameLong' product.json) && \
	setNameShort="setpath([\"nameShort\"]; \"$nameShort\")" && \
	setNameLong="setpath([\"nameLong\"]; \"$nameLong\")" && \
	setExtensionsGalleryItemUrl="setpath([\"extensionsGallery\", \"itemUrl\"]; \"{{extensionsGalleryItemUrl}}\")" && \
	addTrustedDomain=".linkProtectionTrustedDomains += [\"{{trustedDomain}}\"]" && \
	jqCommands="${setNameShort} | ${setNameLong} | ${setExtensionsGalleryItemUrl} | ${addTrustedDomain}" && \
	cat product.json | jq "${jqCommands}" > product.json.tmp && \
	mv product.json.tmp product.json && \
	jq '{nameLong,nameShort}' product.json

RUN yarn gulp vscode-web-min \
	&& yarn gulp vscode-reh-linux-x64-min

FROM scratch

COPY --from=code_builder --chown=33333:33333 /vscode-web/ /ide/
COPY --from=code_builder --chown=33333:33333 /vscode-reh-linux-x64/ /ide/
