resource "oci_core_volume" "FoggyKitchenWebserverBlockVolume100G" {
  availability_domain = var.ADs[2]
  compartment_id = oci_identity_compartment.FoggyKitchenCompartment.id
  display_name = "FoggyKitchenWebserver BlockVolume 100G"
  size_in_gbs = "100"
}

resource "oci_core_volume_attachment" "FoggyKitchenWebserver1BlockVolume100G_attach" {
    attachment_type = "iscsi"
    compartment_id = oci_identity_compartment.FoggyKitchenCompartment.id
    instance_id = oci_core_instance.FoggyKitchenWebserver1.id
    volume_id = oci_core_volume.FoggyKitchenWebserverBlockVolume100G.id
    is_shareable = true
}

resource "oci_core_volume_attachment" "FoggyKitchenWebserver2BlockVolume100G_attach" {
    attachment_type = "iscsi"
    compartment_id = oci_identity_compartment.FoggyKitchenCompartment.id
    instance_id = oci_core_instance.FoggyKitchenWebserver2.id
    volume_id = oci_core_volume.FoggyKitchenWebserverBlockVolume100G.id
    is_shareable = true
}