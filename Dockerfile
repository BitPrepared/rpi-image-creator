FROM packer-builder-arm:local

ENV DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt,id=apt \
    apt update \
    && apt install software-properties-common gpg-agent --no-install-recommends -y \
    && add-apt-repository --yes --update ppa:ansible/ansible \
    && apt install ansible --no-install-recommends -y \
    && ansible-galaxy collection install ansible.posix \
    # install other Ansible roles here if needed
    && (rm -f /var/cache/apt/archives/*.deb \
    /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin /var/lib/apt/lists/* || true)

COPY .packerconfig.pkr.hcl /root/.packerconfig.pkr.hcl