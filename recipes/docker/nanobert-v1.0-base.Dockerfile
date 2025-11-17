FROM 4geniac/almalinux:9.5_sdk-miniforge-24.11.3-2

RUN apt update && apt install -y libtiff

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


COPY . /app/NanoBert

WORKDIR /app/NanoBert

RUN conda create -y -n nanoBert_env && conda install -y -n nanoBert_env --file nanobert.yml

RUN mkdir /opt/etc

RUN /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment NanoBert' > ~/.bashrc \
&& /opt/conda/bin/conda init bash \
&& echo 'conda activate nanoBert_env' >> ~/.bashrc \
&& cp ~/.bashrc /opt/etc/bashrc

