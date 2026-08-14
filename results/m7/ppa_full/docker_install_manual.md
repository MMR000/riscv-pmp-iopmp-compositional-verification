# Docker installation (manual — sudo required)

Host: Ubuntu 24.04.4 LTS (noble), x86_64.

This environment cannot run `sudo` non-interactively (`sudo -n` fails; sudoers/audit errors under sandbox).
Run the following **on the host** in a terminal where you can authenticate:

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF_SRC
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF_SRC

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# If systemd is available:
sudo systemctl enable --now docker || true

sudo docker run --rm hello-world
sudo docker run --rm ubuntu:22.04 nproc
```

Optional Phase A tooling cleanup:

```bash
sudo apt install -y libelf-dev srecord
```

After Docker works, re-run Phase D.1 validation from the repo:

```bash
export DOCKER_CMD="sudo docker"
cd third_party/OpenROAD-flow-scripts/flow
# Prefer pinned ORFS docker_shell once image is available
./util/docker_shell bash -lc 'yosys -V; openroad -version; yosys -m slang -p "slang_version"'
./util/docker_shell make DESIGN_CONFIG=./designs/nangate45/gcd/config.mk
./util/docker_shell make DESIGN_CONFIG=./designs/sky130hd/ibex/config.mk
```

Do **not** launch J0–J3 until both GCD and sky130hd/ibex finish successfully.
