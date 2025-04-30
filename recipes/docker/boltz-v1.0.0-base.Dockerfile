FROM docker.io/ubuntu:24.04

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y wget gcc g++ git build-essential libssl-dev pip python3.12-venv python3.12-full pipx

RUN mkdir /app
RUN mkdir /app/boltz

RUN mkdir /opt/boltz
WORKDIR /opt/boltz
RUN python3.12 -m venv boltz
RUN bash boltz/bin/activate
RUN pipx install boltz==1.0.0
WORKDIR ~
RUN apt autoremove -y && apt remove --purge -y wget git && apt clean -y
RUN rm -rf /var/lib/apt/lists/* /root/.cache


