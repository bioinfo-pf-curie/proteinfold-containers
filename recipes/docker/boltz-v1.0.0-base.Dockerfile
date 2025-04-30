FROM docker.io/nvidia/cuda:12.6.0-base-ubuntu24.04

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y wget gcc g++ git build-essential libssl-dev pip python3.12-venv python3.12-full pipx

RUN mkdir /opt/boltz
WORKDIR /opt/boltz
RUN pipx install boltz==1.0.0
RUN export PATH=/.local/bin:$PATH
WORKDIR /
RUN apt autoremove -y && apt remove --purge -y wget git && apt clean -y
RUN rm -rf /var/lib/apt/lists/* /root/.cache
ENV PATH=/.local/bin:$PATH

