# Ansible Role for configure cloud-init.

**summary**

Role to configure cloud-init.

From [redhat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_and_managing_cloud-init_for_rhel_8/index): cloud-init is a software package that automates the initialization of cloud instances during system boot. 
You can configure cloud-init to perform a variety of tasks. Some sample tasks that cloud-init can perform include:

  * Configuring a host name
  * Installing packages on an instance
  * Running scripts
  * Suppressing default virtual machine (VM) behavior 


**!Attention!**

This role uses dicts() as data storage for the meta-, network-, user- and vendor- configuration. However, these must be formatted and passed in yaml in order to use by cloud-init. A jinja2 macro is used for this. This produced produces "blank lines" in certain constellations, which, however, are not problematic for the functionality. To remove them anyway, I suggest using "ansible.buildin.lineinfile", see example below. 
Since the file is then first generated with "blank lines" and then cleaned up by "lineinfile", "changes" will always occur.

**Tests**
I tested this role with kvm and lxd/lxc. In principle, however, the CD created with "virt" should also work with other hypervisors. After a successful test please send a feedback.

| hypervisor | container type | description |
| --- | ------------- | ----------- |
| kvm || works |
|| lxd | works |

**playbook sketch - create vm**
```yaml
- hosts: kvm-host.example.com
  vars:
    cloud_init_iso_dir: '/var/lib/libvirt/images/'
    cloudinit_fqdn: 'mordor.example.com'
    cloudinit_metadata_rendering: virt
  tasks: []
- name: create vm
  import_role: cloud-init
```

## Keys to implement
| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_rendering | container | **container** or **virt**, _default_ is **container** |
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
| cloudinit_network_raw | See section example | Own dict what should be rendered to a configuration. |

### user-data
| Key | Example-Value | Description |
| --- | ------------- | ----------- |
| cloudinit_userdata_raw | See section example | Own dict what should be rendered to a configuration. |
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
    - true
  packages:
    - openssh-server
  users:
    - name: "{{ user_admin.name }}"
      groups:
        - adm
        - sudo
        - dip
        - plugdev
        - cdrom
      passwd: "{{ user_admin.pass_hash }}"
      lock_passwd: false
      shell: /bin/bash
      ssh_import_id:
        - "{{ user_admin.github_account }}"
      ssh_authorized_keys:
        - "{{ user_admin.ssh_authorized_keys }}"
      sudo:
        - ALL=(ALL) ALL
  prefer_fqdn_over_hostname: True
  fqdn: '{{ cloudinit_fqdn }}'
```

### network-data
```yaml
cloudinit_network_rawdata:
  version: 2
  renderer: networkd
  ethernets: 
    eth0:
      dhcp4: true
      dhcp6: false
```

## License

see [LICENSE](LICENSE)
