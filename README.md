# Ansible Role for configure cloud-init.

**summary**

Role to configure cloud-init.

From [redhat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_and_managing_cloud-init_for_rhel_8/index): cloud-init is a software package that automates the initialization of cloud instances during system boot. 
You can configure cloud-init to perform a variety of tasks. Some sample tasks that cloud-init can perform include:

  * Configuring a host name
  * Installing packages on an instance
  * Running scripts
  * Suppressing default virtual machine (VM) behavior 

Cloud-Init data can be passed to the images via different ways.
Currently, this role supports the transfer of dictionaries (e.g. LXD or ESX) and creation of a CD that is mounted at boot time. The last option is supported by all known HyperVisors, but is messy to use, as this virtual CD should be ejected before users log in. So if you use the Cloudinit and the provided CD support you have to implement some thing to implement this.


**!Attention!**

This role support dicts() as data storage for the meta-, network-, user- and vendor- configuration.
Ansible represented the dicts as json.
However, these must be formatted and passed in yaml in order to use by cloud-init. A jinja2 macro is used for this. This produced produces "blank lines" in certain constellations, which, however, are not problematic for the functionality. To remove them anyway, I suggest using "ansible.buildin.lineinfile", see example below. 
Since the file is then first generated with "blank lines" and then cleaned up by "lineinfile", "changes" will always occur.

**Tests**
I tested this role with kvm and lxd/lxc. In principle, however, the CD created with "iso" should also work with other hypervisors. After a successful test please send a feedback.

| hypervisor | container type | test |
| --- | ------------- | ----------- |
| esx || works |
| kvm || works |
|| lxd | works |

**playbook sketch - create vm**
```yaml
- hosts: kvm-host.example.com
  vars:
    cloud_init_iso_dir: '/var/lib/libvirt/images/'
    cloudinit_fqdn: 'mordor.example.com'
    cloudinit_metadata_rendering: iso
  tasks: []
- name: create vm
  import_role: cloud-init
```

### Notes on ESX
ESXi only supports "user-data" and "meta-data", as the network data should be set via the VMWare tools.
At the [documentation](https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html) the network configuration is set by meta-data. In my tests cases that didn't work by ansible. 

With default images (cloud-images) these VMWare tools are not installed and therefore there is a chicken and egg problem.
This role uses the user data to set the configuration in the VM and then install the VMWare tools.

If the variable "esx | bool" is true, the network-config is created before user-data and injected to userdata. That is mostly a workaround, but it works well.

## Keys to implement
| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_rendering | var | **var** or **iso**, _default_ is **var** |
| cloudinit_iso_dest_dir | '/var/lib/libvirt/images/' | path to store the ISO |

## Sections
### meta-data
| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_metadata_dsmode | local, net, pass | Default: **net**. The difference between ‘local’ and ‘net’ is that local will not require networking to be up before user-data actions (or boothooks) are run. |
| cloudinit_userdata_raw | - | Own dict what should be rendered to a configuration. [See at](https://cloudinit.readthedocs.io/en/latest/topics/datasources/configdrive.html) |

### network-config
Look at: [Netplan - Examples](https://netplan.io/examples/) for configuration examples.

The default config is configure **eth0** by **dhcp**.
If the target is a vm, the interface will have a different identifier-name.
From my point of view, the best option is to assign a name to the VM's network card via the MAC. 

| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_network_raw | See section example, or defaults/main/networkconfig.yml | Own dict what should be rendered to a configuration. |

### user-data
| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_userdata_raw | See section example, or defaults/main/userdata.yml | Own dict what should be rendered to a configuration. |
| cloudinit_packages | ['openssh-server', 'python-pip', 'python-venv'] | packages to install by cloud-init |

### vendor-data
| Key | Example-Value | Description |
| --- | ------------- | ----------- |

## example
### user-data
```yaml
cloudinit_userdata_raw:
  runcmd:
  - [touch, /tmp/user_data_was_run]
  package_update:
    - True
  packages:
    - openssh-server
  users:
    - name: "{{ vault_user_admin.name }}"
      groups:
        - adm
        - sudo
        - dip
        - plugdev
        - cdrom
      passwd: "{{ vault_user_admin.password_hash }}"
      lock_passwd: False
      shell: /bin/bash
      ssh_import_id:
        - "{{ vault_user_admin.github_account }}"
      ssh_authorized_keys:
        - "{{ vault_user_admin.ssh_authorized_keys }}"
      sudo:
        - ALL=(ALL) ALL
  prefer_fqdn_over_hostname: True
  fqdn: '{{ cloudinit_fqdn }}'
```

### network-config
#### dhcp
```yaml
cloudinit_network_rawdata:
  network:
    version: 2
    renderer: networkd
    ethernets: 
      eth0:
        dhcp4: True
        dhcp6: False
```
#### static
```yaml
cloudinit_network_raw:
  network:
    version: 2
    renderer: networkd
    ethernets:
      nics:
        match:
          enp*
        dhcp4: False
        addresses: [192.168.178.38/24]
        gateway4: 192.168.178.1
        nameservers:
          addresses: [192.168.178.13]
```
## License

see [LICENSE](LICENSE)
