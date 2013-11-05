class EligibleDeaAdvertisementFilter
  def initialize(dea_advertisements)
    @dea_advertisements = dea_advertisements.dup
  end

  def only_with_disk(minimum_disk)
    @dea_advertisements.select! { |ad| ad.has_sufficient_disk?(minimum_disk) }
    self
  end

  def only_meets_needs(mem, stack)
    @dea_advertisements.select! { |ad| ad.meets_needs?(mem, stack) }
    self
  end

  def only_fewest_instances_of_app(app_id)
    fewest_instances_of_app = @dea_advertisements.map { |ad| ad.num_instances_of(app_id) }.min
    @dea_advertisements.select! { |ad| ad.num_instances_of(app_id) == fewest_instances_of_app }
    self
  end

  def upper_half_by_memory
    unless @dea_advertisements.empty?
      @dea_advertisements.sort_by! { |ad| ad.available_memory }
      min_eligible_memory = @dea_advertisements[@dea_advertisements.size/2].available_memory
      @dea_advertisements.select! { |ad| ad.available_memory >= min_eligible_memory }
    end

    self
  end

  # try to distribute the app instances across zones evenly
  def only_in_the_zone_with_fewest_instances(app_id, all_ads)
    zones = find_all_zones(all_ads)

    unless @dea_advertisements.empty? || zones.empty? || zones.length == 1
      zone_name_to_inst_num = zone_instnum_map(app_id, zones, all_ads)
      # find all dea_ads for each zone
      zone_name_to_ads = {}
      @dea_advertisements.each do |ad|
        if zone_name_to_inst_num.has_key?(ad.zone)
          if zone_name_to_ads.has_key?(ad.zone)
            zone_name_to_ads[ad.zone].push(ad)
          else
            zone_name_to_ads.store(ad.zone, Array.new.push(ad))
          end
        end
      end

      # get the dea_ads from the zone that have the min app instances
      @dea_advertisements = []
      min_inst_num = -1
      zone_name_to_inst_num.each do |zone_name, inst_num|
        dea_ads = zone_name_to_ads[zone_name]
        if dea_ads && !dea_ads.empty?
          if min_inst_num < 0 || min_inst_num > inst_num
            @dea_advertisements = dea_ads
            min_inst_num = inst_num
          end
        end
      end
    end

    self
  end

  def sample
    @dea_advertisements.sample
  end

  private

  def find_all_zones(all_ads)
    zones = []
    all_ads.each do |ad|
      zones.push(ad.zone)
    end
    zones.uniq
  end

  def zone_instnum_map(app_id, zones, all_ads)
    zone_name_to_inst_num = {}
    if zones && !zones.empty?
      zones.each do |zone|
        zone_name_to_inst_num.store(zone.name, 0)
      end
    end

    # Calculate the num of app instances in each zone
    all_ads.each do |ad|
      if zone_name_to_inst_num.has_key?(ad.zone)
        zone_name_to_inst_num[ad.zone] += ad.num_instances_of(app_id)
      end
    end

    zone_name_to_inst_num
  end
end