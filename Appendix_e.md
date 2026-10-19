# Appendix E: Local Lab Infrastructure Specifications

This appendix provides a rigorous, enterprise-oriented, and fully hands-on blueprint for deploying the complete local lab topology required for advanced cloud-native infrastructure engineering, high-availability virtualization, and distributed storage workflows aligned with enterprise standards. \

## E.1. Workspace Node Baseline: Debian 13 Workstation with KVM Nested Virtualization

The foundational workspace node serves as the hypervisor host for all subsequent virtualized infrastructure. It runs **Debian 13 (Trixie)** configured with the Linux Kernel KVM (Kernel-based Virtual Machine) module and `libvirt` stack.

### E.1.1. Host System Prerequisites & Hardware Baseline

* **Minimum Host Resources:** 8-Core CPU (Intel VT-x or AMD-V enabled), 64GB ECC RAM, 1TB NVMe PCIe 4.0 Storage Pool.

* **Operating System:** Debian 13 Minimal Server installation with standard system utilities.

### E.1.2. Installing KVM, QEMU, and Libvirt Packages
Execute the following commands on the Debian 13 host to install the virtualization toolchain:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst cpu-checker
sudo systemctl enable --now libvirtd
sudo usermod -aG kvm,libvirt $USER
```

### E.1.3. Configuring Nested Virtualization
Because the lab environment runs Proxmox VE nodes inside virtual machines, nested virtualization must be explicitly enabled on the Debian 13 host.

1. Verify hardware virtualization support:

   ```bash
   kvm-ok
   ```
   *Expected output:* `INFO: /dev/kvm exists. KVM acceleration can be used`

3. Enable nested virtualization for Intel CPUs:

   ```bash
   sudo modprobe -r kvm_intel
   sudo modprobe kvm_intel nested=1
   cat /sys/module/kvm_intel/parameters/nested
   ```
   *Expected output:* `Y` or `1`

5. Make the configuration persistent across reboots:

   ```bash
   echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm_intel.conf
   ```
   *(For AMD processors, substitute `kvm_intel` with `kvm_amd` and `nested=1`).*

### E.1.4. Bridged Networking Configuration (`br0`)

To allow virtual machines to communicate directly with external subnets and each other across nodes, configure a Linux bridge (`br0`) via NetworkManager or `/etc/network/interfaces`. Using `/etc/network/interfaces`:

```ini
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual

auto br0
iface br0 inet dhcp
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
```

Apply the network configuration:

```bash
sudo systemctl restart networking
```

## E.2. Hyper-Converged Infrastructure (HCI) Setup

The core infrastructure consists of a production-grade Hyper-Converged Infrastructure (HCI) cluster using **Proxmox VE (PVE 8.x/9.x)** and distributed block storage via **Ceph**.

### E.2.1. 3-Node Baseline Proxmox VE Hyper-Converged Ceph Storage Cluster

Deploy three nested virtual machines (`pve-node1`, `pve-node2`, `pve-node3`), each assigned 8 vCPUs, 16GB RAM, 50GB OS disk (`/dev/sda`), and three 100GB raw disks (`/dev/sdb`, `/dev/sdc`, `/dev/sdd`) designated for Ceph Object Storage Daemons (OSDs).

#### Network Segmentation Table
| Network Name | CIDR / VLAN | Purpose |
| :--- | :--- | :--- |
| **Management** | `192.168.10.0/24` (VLAN 10) | PVE GUI, SSH, API Access |
| **Cluster Corosync**| `192.168.20.0/24` (VLAN 20) | High-availability cluster heartbeat |
| **Ceph Public** | `192.168.30.0/24` (VLAN 30) | Client-to-storage data traffic |
| **Ceph Cluster** | `192.168.40.0/24` (VLAN 40) | Inter-OSD replication traffic |

#### Initializing the PVE Cluster

1. On `pve-node1`, initialize the cluster:

   ```bash
   pvecm create enterprise-cluster
   ```
   
3. Retrieve the join command/fingerprint from `pve-node1` and join `pve-node2` and `pve-node3`:

   ```bash
   pvecm join 192.168.10.11 --fingerprint <SHA256_FINGERPRINT>
   ```

#### Provisioning the Ceph Storage Cluster

1. Navigate to **PVE Web UI -> Datacenter -> Ceph -> Install** on all three nodes using the stable repository (e.g., Ceph Reef or Squid).

2. Create the Ceph Monitor (`MON`) and Ceph Manager (`MGR`) services across all three nodes.

3. Configure Ceph Pools with optimal Placement Groups ($PG$) calculated via the formula:
   $$\text{PG\_count} = \frac{\text{OSD\_count} \times 100}{\text{size}}$$
   For 9 OSDs with a replica size of 3, set $\text{pg\_num} = 128$.

4. Create OSDs utilizing BlueStore on `/dev/sdb`, `/dev/sdc`, and `/dev/sdd` via the GUI or CLI:

   ```bash
   pveceph osd create /dev/sdb
   pveceph osd create /dev/sdc
   pveceph osd create /dev/sdd
   ```

### E.2.2. Scale-Out Architecture: Injecting 2 Additional Compute/Storage Nodes

To validate high availability and dynamic cluster expansion, scale the cluster horizontally by injecting two additional nodes: `pve-node4` and `pve-node5`.

1. Provision and join `pve-node4` and `pve-node5` to `enterprise-cluster`.

2. Attach two 100GB OSD drives (`/dev/sdb`, `/dev/sdc`) to each new node.

3. Expand the Ceph CRUSH map failure domain to rack level (simulated via host weights):

   ```bash
   ceph osd crush add-bucket rack1 rack
   ceph osd crush move pve-node1 root=default rack=rack1
   ceph osd crush move pve-node2 root=default rack=rack1
   ```
   
5. Verify cluster health and rebalancing progress:

   ```bash
   ceph -s
   ```
 
   *Expected status:* `HEALTH_OK`, with all placement groups active and clean (`active+clean`).

## E.3. Enterprise Cluster Management: Proxmox Datacenter Manager (PDM) Integration

Managing multi-cluster edge and core environments requires centralized control planes. We deploy **Proxmox Datacenter Manager (PDM)** as a dedicated standalone LXC container or VM on the workspace node.

### E.3.1. PDM Installation and Setup

1. Deploy a Debian 13 VM/LCT container for PDM.

2. Add the Proxmox enterprise/no-subscription repository and install PDM:

   ```bash
   echo "deb http://download.proxmox.com/debian/pdm trix-no-subscription main" > /etc/apt/sources.list.d/pdm.list
   wget https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg
   sudo apt update && sudo apt install proxmox-datacenter-manager -y
   ```

### E.3.2. Registering Remote PVE Clusters with PDM

1. Generate an API Token on `pve-node1` (`enterprise-cluster`) with appropriate privileges (`Datacenter.Allocate`, `VM.Audit`, etc.).

2. Log into the PDM Web UI (`https://<pdm-ip>:8443`).

3. Navigate to **Remotes -> Add Remote Cluster**, input the API endpoint, cluster fingerprint, and administrative credentials.

4. Verify unified multi-cluster views, cross-cluster guest migration readiness, and global metrics aggregation.

## E.4. Enterprise Backup Architecture: Dedicated Proxmox Backup Server (PBS) Target & Datastore Engine Configuration

To achieve data protection, immutability, and efficient deduplication, a dedicated **Proxmox Backup Server (PBS)** instance is integrated into the lab topology.

### E.4.1. PBS Installation & Storage Pool Architecture

1. Deploy a dedicated VM (`pbs-server01`) running PBS 3.x/4.x.

2. Configure a ZFS pool (`tank`) across a dedicated 200GB virtual NVMe disk with compression enabled:

   ```bash
   zpool create -f tank mirror /dev/sdb /dev/sdc
   zfs set compression=zstd-3 tank
   ```
   
4. Create a dedicated datastore named `enterprise-store` targeting `/tank/store`.

### E.4.2. Encryption & Namespace Configuration

1. Initialize client-side encryption keys on PBS to ensure zero-knowledge architecture:

   ```bash
   proxmox-backup-client key create /root/pbs-enc-key.json --kdf pbkdf2
   ```
   
3. Configure namespaces within the datastore to segment backups by environment (`/production`, `/staging`, `/development`).

4. Add the PBS storage target inside the PVE cluster (`Datacenter -> Storage -> Add -> Proxmox Backup Server`), inputting the fingerprint, datastore name, and encryption key.

5. Schedule automated nightly snapshot backup jobs with retention policies (Prune Schedule: `keep-daily=7, keep-weekly=4, keep-monthly=12`).

## E.5. Ansible Deployment Playbooks: Automated Bootstrap of the Complete Lab Topology

To eliminate manual configuration drift and provision the entire lab in minutes, use the following production-grade Ansible playbook structure.

### E.5.1. Directory Structure

```text
playbooks/
├── inventory/
│   └── hosts.yml
├── roles/
│   ├── workspace_kvm/
│   ├── pve_cluster/
│   ├── ceph_storage/
│   └── pbs_server/
└── site.yml
```

### E.5.2. Master Orchestration Playbook (`site.yml`)

```yaml
---
- name: Bootstrap Complete Enterprise Lab Topology
  hosts: localhost
  connection: local
  gather_facts: yes
  become: yes

  pre_tasks:
    - name: Ensure required local packages are installed
      apt:
        name:
          - qemu-kvm
          - libvirt-daemon-system
          - bridge-utils
          - python3-libvirt
        state: present
        update_cache: yes

  roles:
    - role: workspace_kvm
    - role: pve_cluster
    - role: ceph_storage
    - role: pbs_server

  post_tasks:
    - name: Verify cluster health via API
       uri:
         url: "https://192.168.10.11:8006/api2/json/cluster/status"
         method: GET
         validate_certs: no
       register: cluster_status
    - name: Display Cluster Health Result
      debug:
        msg: "Proxmox Cluster bootstrap completed successfully. Status: {{ cluster_status.status }}"
```

### E.5.3. Role: Proxmox Cluster Initialization (`roles/pve_cluster/tasks/main.yml`)

```yaml
---
- name: Configure Proxmox VE repository lists
  template:
    src: pve-no-subscription.list.j2
    dest: /etc/apt/sources.list.d/pve-no-subscription.list
    owner: root
    group: root
    mode: '0644'

- name: Update apt cache and upgrade nodes
  apt:
    update_cache: yes
    upgrade: safe

- name: Initialize primary PVE node cluster if not already formed
  command: pvecm create enterprise-cluster
  args:
    creates: /etc/corosync/corosync.conf
  when: inventory_hostname == 'pve-node1'

- name: Fetch cluster join information
  slurp:
    src: /etc/pve/corosync.conf
  register: corosync_conf
  when: inventory_hostname == 'pve-node1'
```

## E.6. Verification Checklist & Lab Sign-Off

Before proceeding with high-availability testing, failover simulations, or LPI 701-200 operational exercises, verify the following acceptance criteria:

1. `virsh list --all` confirms all 5 PVE nodes and 1 PBS server are running with nested virtualization active.

2. `pvecm status` reports all 5 nodes online under `enterprise-cluster`.

3. `ceph -s` reports `HEALTH_OK` with full OSD map coverage across all storage nodes.

4. PDM successfully displays unified graphs and performance metrics across all registered clusters.

5. A test VM backup executed from PVE to the PBS datastore completes with verified client-side encryption and deduplication.
