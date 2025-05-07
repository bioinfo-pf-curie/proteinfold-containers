FROM docker.io/nvidia/cuda:12.6.0-base-ubuntu24.04

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y  wget gcc g++ git build-essential libssl-dev pip python3.12-venv python3.12-full pipx
WORKDIR /opt/
RUN git clone https://github.com/jwohlwend/boltz.git
WORKDIR /opt/boltz
RUN python3.12 -m venv boltz_env
ENV PATH="/opt/boltz/boltz_env/bin:$PATH"
RUN pip install --upgrade pip && pip install -e .
WORKDIR /
RUN apt autoremove -y && apt remove --purge -y wget git && apt clean -y
RUN rm -rf /var/lib/apt/lists/* /root/.cache

