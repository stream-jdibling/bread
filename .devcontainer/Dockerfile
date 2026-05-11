FROM mcr.microsoft.com/devcontainers/base:trixie

RUN apt-get update && apt-get install -y \
    iputils-ping \
    vim \
    rsync \
    && rm -rf /var/lib/apt/lists/*

COPY bash_aliases /home/vscode/.bash_aliases
RUN chown vscode:vscode /home/vscode/.bash_aliases