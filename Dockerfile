ARG BASE_IMAGE=dreg.cloud.sdu.dk/ucloud-apps/rstudio:4.5.1
FROM $BASE_IMAGE

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

LABEL software="Transcriptomics sandbox" \
    author="Samuele Soraggi <samuele@birc.au.dk>, Alba Refoyo Martinez" \
    license="MIT" \
    description="Transcriptomics sandbox with modules and courses"


ENV G_SLICE=always-malloc
ENV PIXI_PROJECT=/opt/pixi/envs/course_env
ENV PIXI_ENV=/opt/pixi/envs/course_env/.pixi/envs/default
ENV SHELL=/bin/bash
ENV R_HOME=
ENV PATH=$PATH:/home/$USER/bin:/home/$USER/.pixi/bin

## Set shell
USER 0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# System dependencies
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    software-properties-common \
    pandoc \
    libicu-dev \
    libcurl4-openssl-dev \
    libjpeg9 libssl-dev \
    libxml2-dev \
    libmagick++-dev \
    libfftw3-dev \
    libhdf5-dev \
    libgsl-dev \
    liblzma-dev \
    libdeflate-dev \
    zlib1g-dev \
    libbz2-dev \
    texlive-fonts-recommended \
    texlive-plain-generic \
    texlive-xetex xxd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
    /opt/pixi \
    "/home/${USER}/.R" \
    /usr/Cirrocumulus/Data \
 && chown -R "${USERID}:${GROUPID}" \
    /opt/pixi \
    "/home/${USER}/.R" \
    /usr/Cirrocumulus

WORKDIR /sbin

ARG TINI_=${TINI_:-"latest"}
RUN if [[ "${TINI_}" = "latest" ]]; then export TINI_=$(curl -s https://api.github.com/repos/krallin/tini/releases/latest | jq -r '.tag_name'); fi \
 && wget -q "https://github.com/krallin/tini/releases/download/${TINI_}/tini" \
 && chmod +x tini

USER $USERID

## Copy input files
COPY --chown=$USERID:$GROUPID envs /tmp/envs
COPY --chown=$USERID:$GROUPID scripts /tmp

# Install Pixi and create the course environment
WORKDIR /opt/pixi

RUN curl -fsSL https://pixi.sh/install.sh | bash \
 && mkdir -p "$PIXI_PROJECT"

WORKDIR $PIXI_PROJECT

RUN pixi init --import /tmp/envs/environment.yml \
 && pixi install --run-post-link-scripts \
 && pixi run python -m pip install -r /tmp/envs/requirements_pixi.txt 

RUN --mount=type=secret,id=github_pat,env=GITHUB_PAT \
    pixi run --manifest-path /opt/pixi/envs/course_env/pixi.toml \
    Rscript /tmp/external_packages_for_pixi.R

# enable resource usage topbar
RUN RESOURCE_SCHEMA="/opt/pixi/envs/course_env/.pixi/envs/default/share/jupyter/labextensions/@jupyter-server/resource-usage/schemas/@jupyter-server/resource-usage/topbar-item.json" && \
    if [ -f "$RESOURCE_SCHEMA" ]; then \
        sed -i 's/"default": false/"default": true/g' "$RESOURCE_SCHEMA"; \
    fi
    
RUN cat >> "/home/${USER}/.bashrc" <<'EOF'
export PIXI_PROJECT=/opt/pixi/envs/course_env
export PIXI_ENV="$PIXI_PROJECT/.pixi/envs/default"
export PATH="$PIXI_ENV/bin:$HOME/.pixi/bin:$PATH"
EOF

## cirrocumulus example data
COPY --chown=$USERID:$GROUPID ./pbmc3k /usr/Cirrocumulus/Data/pbmc3k

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bash"]

WORKDIR /work