resource "null_resource" "FoggyKitchenWebserver_oci_iscsi_attach" {
 depends_on = [oci_core_volume_attachment.FoggyKitchenWebserver1BlockVolume100G_attach]

 provisioner "remote-exec" {
    connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
     inline = ["sudo /bin/su -c \"rm -Rf /home/opc/iscsiattach.sh\""]
  }

 provisioner "remote-exec" {
    connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
     inline = ["sudo /bin/su -c \"rm -Rf /home/opc/iscsiattach.sh\""]
  }

 provisioner "file" {
    connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
    source     = "iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

 provisioner "file" {
    connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
    source     = "iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
            connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
  inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
            "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
            "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
            connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
  inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
            "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
            "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

}


resource "null_resource" "FoggyKitchenWebserver1_config_OCFS" {
 depends_on = [oci_core_instance.FoggyKitchenWebserver1,null_resource.FoggyKitchenWebserver_oci_iscsi_attach]
 provisioner "remote-exec" {
        connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
  inline = ["echo '== 1. Installing OCFS2'",
            "sudo yum install ocfs2-tools-devel ocfs2-tools -y",

            "echo '== 2. Adding cluster to o2cb'",
            "sudo o2cb add-cluster ociocfs2", 

            "echo '== 3. Adding nodes to o2cb'",
            "sudo o2cb add-node ociocfs2 foggykitchenwebserver1 --ip ${data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.private_ip_address}",
            "sudo o2cb add-node ociocfs2 foggykitchenwebserver2 --ip ${data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.private_ip_address}",
            
             "echo '== 4. Modify /etc/sysconfig/o2cb and start odcb'",
             "sudo /bin/su -c \"echo 'O2CB_ENABLED=true' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_STACK=o2cb' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_BOOTCLUSTER=ociocfs2' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_HEARTBEAT_THRESHOLD=31' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_IDLE_TIMEOUT_MS=30000' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_KEEPALIVE_DELAY_MS=2000' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_RECONNECT_DELAY_MS=2000' >> /etc/sysconfig/o2cb\"",
             "sudo /sbin/o2cb.init start", 

             "echo '== 5. Systemctl enable o2cb'",
             "sudo systemctl enable o2cb",
             "sudo systemctl enable ocfs2",

             "echo '== 6. Mkfs.ocfs2'",
             "sudo mkfs.ocfs2 -L \"ocfs2\" /dev/sdb",

             "echo '== 7. Updating /etc/fstab with OCFS2 mount point'",
             "sudo mkdir /ocfs2",
             "sudo /bin/su -c \"echo '/dev/sdb /ocfs2 ocfs2     _netdev,defaults   0 0' >> /etc/fstab\"",

             "echo '== 8. Modify the kernel'",
             "sudo sysctl kernel.panic=30",
             "sudo sysctl kernel.panic_on_oops=1",
             "sudo /bin/su -c \"echo 'kernel.panic=30'>> /etc/sysctl.conf\"",
             "sudo /bin/su -c \"echo 'kernel.panic_on_oops=1'>> /etc/sysctl.conf\"",

             "echo '== 9. Mount /ocfs2'",
             "sudo mount -a"
            ]

  }
}

resource "null_resource" "FoggyKitchenWebserver2_config_OCFS" {
 depends_on = [oci_core_instance.FoggyKitchenWebserver2, null_resource.FoggyKitchenWebserver1_config_OCFS, null_resource.FoggyKitchenWebserver_oci_iscsi_attach]
 provisioner "remote-exec" {
        connection {
                type     = "ssh"
                user     = "opc"
                host     = data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.public_ip_address
                private_key = file(var.private_key_oci)
                script_path = "/home/opc/myssh.sh"
                agent = false
                timeout = "10m"
        }
  inline = ["echo '== 1. Installing OCFS2'",
            "sudo yum install ocfs2-tools-devel ocfs2-tools -y",

            "echo '== 2. Adding cluster to o2cb'",
            "sudo o2cb add-cluster ociocfs2", 

            "echo '== 3. Adding nodes to o2cb'",
            "sudo o2cb add-node ociocfs2 foggykitchenwebserver1 --ip ${data.oci_core_vnic.FoggyKitchenWebserver1_VNIC1.private_ip_address}",
            "sudo o2cb add-node ociocfs2 foggykitchenwebserver2 --ip ${data.oci_core_vnic.FoggyKitchenWebserver2_VNIC1.private_ip_address}",
            
             "echo '== 4. Modify /etc/sysconfig/o2cb and start odcb'",
             "sudo /bin/su -c \"echo 'O2CB_ENABLED=true' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_STACK=o2cb' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_BOOTCLUSTER=ociocfs2' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_HEARTBEAT_THRESHOLD=31' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_IDLE_TIMEOUT_MS=30000' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_KEEPALIVE_DELAY_MS=2000' >> /etc/sysconfig/o2cb\"",
             "sudo /bin/su -c \"echo 'O2CB_RECONNECT_DELAY_MS=2000' >> /etc/sysconfig/o2cb\"",
             "sudo /sbin/o2cb.init start", 

             "echo '== 5. Systemctl enable o2cb'",
             "sudo systemctl enable o2cb",
             "sudo systemctl enable ocfs2",

             "echo '== 6. Updating /etc/fstab with OCFS2 mount point'",
             "sudo mkdir /ocfs2",
             "sudo /bin/su -c \"echo '/dev/sdb /ocfs2 ocfs2     _netdev,defaults   0 0' >> /etc/fstab\"",

             "echo '== 7. Modify the kernel'",
             "sudo sysctl kernel.panic=30",
             "sudo sysctl kernel.panic_on_oops=1",
             "sudo /bin/su -c \"echo 'kernel.panic=30'>> /etc/sysctl.conf\"",
             "sudo /bin/su -c \"echo 'kernel.panic_on_oops=1'>> /etc/sysctl.conf\"",

             "echo '== 8. Mount /ocfs2'",
             "sudo mount -a"
            ]

  }
}
