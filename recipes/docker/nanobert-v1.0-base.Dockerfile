FROM 4geniac/almalinux:9.5_sdk-miniforge-24.11.3-2

RUN dnf install --setopt=fastestmirror=1 --setopt=metadata_expire=0 -y libtiff && dnf clean all

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


COPY . /app/NanoBert

WORKDIR /app/NanoBert

RUN conda env create -y -n nanoBert_env --file nanobert.yml

RUN mkdir /opt/etc

RUN /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment NanoBert' > ~/.bashrc \
&& /opt/conda/bin/conda init bash \
&& echo 'conda activate nanoBert_env' >> ~/.bashrc \
&& cp ~/.bashrc /opt/etc/bashrc

