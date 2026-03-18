FROM docker.io/nvidia/cuda:12.6.0-base-ubuntu24.04

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y  wget gcc g++ git build-essential libssl-dev pip python3.12-venv python3.12-full pipx libpython3.12-dev


COPY . /app/boltz

RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app/boltz
RUN pip install --upgrade pip && pip install -e .[cuda]

RUN apt autoremove -y && apt remove --purge -y wget git && apt clean -y
RUN rm -rf /var/lib/apt/lists/* /root/.cache


COPY version-info.txt /app/boltz/version-info.txt

RUN mkdir /opt/etc
RUN /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment' > ~/.bashrc \
  && echo 'source /opt/venv/bin/activate' >> ~/.bashrc \
  && cp ~/.bashrc /opt/etc/bashrc
ENV BASH_ENV=/opt/etc/bashrc

RUN echo $'#!/bin/bash\n\
ldconfig\n\
source /opt/etc/bashrc \n\
boltz "$@"' > /app/run_boltz.sh \
ENTRYPOINT ["/app/run_boltz.sh"]
