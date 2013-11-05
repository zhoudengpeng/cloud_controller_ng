require "cloud_controller/nats_messages/advertisment"

class DeaAdvertisement < Advertisement
  def dea_id
    stats["id"]
  end

  def increment_instance_count(app_id)
    stats["app_id_to_count"][app_id] = num_instances_of(app_id) + 1
  end

  def num_instances_of(app_id)
    stats["app_id_to_count"].fetch(app_id, 0)
  end


  # return the zone info that this DEA belongs to
  def zone
    if stats["placement_properties"] && stats["placement_properties"]["zone"]
      stats["placement_properties"]["zone"]
    else
      "default"
    end
  end
end