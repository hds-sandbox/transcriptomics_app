ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

LABEL software="Transcriptomics sandbox" \
    author="Samuele Soraggi <samuele@birc.au.dk>, Alba Refoyo Martinez" \
    license="MIT" \
    description="Transcriptomics sandbox with modules and courses"


ENV G_SLICE=always-malloc
ENV PIXI_PROJECT=/opt/
ENV PIXI_ENV=${PIXI_PROJECT}/.pixi/envs/course-env
ENV R_HOME=$PIXI_ENV/lib/R
ENV R_LIBS_USER=$R_HOME/library
ENV SHELL=/bin/bash
ENV PATH=$PIXI_ENV/bin:/home/$USER/bin:$PATH
ENV RESOURCE_SCHEMA="${PIXI_ENV}/share/jupyter/labextensions/@jupyter-server/resource-usage/schemas/@jupyter-server/resource-usage/topbar-item.json"
ENV JUPYTER_ENV_FILE="https://raw.githubusercontent.com/hds-sandbox/common-files_development/refs/heads/main/jupyterlab_and_plugins.yaml"

## Copy input files
COPY --chown=$USERID:$GROUPID envs/environment.yml ${PIXI_PROJECT}/environment.yml
COPY --chown=$USERID:$GROUPID scripts /tmp
## cirrocumulus example data
COPY --chown=$USERID:$GROUPID ./pbmc3k /usr/Cirrocumulus/Data/pbmc3k

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
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p \
    /opt/pixi \
    "/home/${USER}/.R" \
    /usr/Cirrocumulus/Data \
 && chown -R "${USERID}:${GROUPID}" \
    /opt \
    /opt/pixi \
    "/home/${USER}/.R" \
    /usr/Cirrocumulus

WORKDIR /sbin

ARG TINI_=${TINI_:-"latest"}
RUN if [[ "${TINI_}" = "latest" ]]; then export TINI_=$(curl -s https://api.github.com/repos/krallin/tini/releases/latest | jq -r '.tag_name'); fi \
 && wget -q "https://github.com/krallin/tini/releases/download/${TINI_}/tini" \
 && chmod +x tini

USER $USERID

# Install Pixi and create the course environment
WORKDIR ${PIXI_PROJECT}

RUN curl -fsSL https://pixi.sh/install.sh | bash \
 && export PATH="$HOME/.pixi/bin:$PATH" \
 && mkdir -p "${PIXI_PROJECT}" \
 && curl -fsSL -o /opt/jupyterlab_and_plugins.yml "${JUPYTER_ENV_FILE}" \
 && "$HOME/.pixi/bin/pixi" init \
 && "$HOME/.pixi/bin/pixi" add conda-merge \
 && "$HOME/.pixi/bin/pixi" run conda-merge ./environment.yml ./jupyterlab_and_plugins.yml > ./environment_merged.yml \
 && "$HOME/.pixi/bin/pixi" import --environment course-env --format conda-env ./environment_merged.yml \
 && rm -rf ./pixi/envs/default \
 && cat ./environment_merged.yml

RUN --mount=type=secret,id=github_pat,env=GITHUB_PAT \
 "$HOME/.pixi/bin/pixi" install --environment course-env --run-post-link-scripts \
 && "$HOME/.pixi/bin/pixi" run --environment course-env \
    Rscript /tmp/external_packages_for_pixi.R \
 && jq --arg rpath "$PIXI_ENV/bin/R" '.argv[0] = $rpath' "$PIXI_ENV/share/jupyter/kernels/ir/kernel.json" > /tmp/ir-kernel.json \
 && mv /tmp/ir-kernel.json "$PIXI_ENV/share/jupyter/kernels/ir/kernel.json" \
 && if [ -f "$RESOURCE_SCHEMA" ]; then \
      sed -i 's/"default": false/"default": true/g' "$RESOURCE_SCHEMA"; \
    fi \
 && cat >> "/home/${USER}/.bashrc" <<'EOF'
export PIXI_PROJECT=${PIXI_PROJECT}
export PIXI_ENV=${PIXI_ENV}
export PATH="$PIXI_ENV/bin:$HOME/.pixi/bin:$PATH"
export R_HOME=$PIXI_ENV/lib/R
export R_LIBS_USER=$R_HOME/library
export LD_LIBRARY_PATH="$PIXI_ENV/lib:$LD_LIBRARY_PATH"
EOF

RUN $PIXI_ENV/bin/Rscript -e 'IRkernel::installspec(prefix=Sys.getenv("PIXI_ENV"), name = "r", displayname = "R")' 

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bash"]

WORKDIR /work