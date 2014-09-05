class CronJob < OceanDynamo::Table

  ocean_resource_model index: [:id], search: false,
                       invalidate_member: [],
                       invalidate_collection: []


  dynamo_schema(:id, table_name_suffix: Api.basename_suffix, 
                     create: Rails.env != "production") do
    # Input attributes
    attribute :credentials
    attribute :token
    attribute :steps,                :serialized, default: []
    attribute :cron

    # Output only
    attribute :created_by
    attribute :updated_by
    attribute :cron_structure,       :serialized, default: [nil, nil, nil, nil, nil]
  end


  CRON_DATA = [
    {name: "minutes",      range: [0, 59]},
    {name: "hours",        range: [0, 23]},
    {name: "day_of_month", range: [1, 31]},
    {name: "month",        range: [1, 12], list: %w(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC), list_base: 1},
    {name: "day_of_week",  range: [0, 6], list: %w(SUN MON TUE WED THU FRI SAT), list_base: 0}
  ]
  

  # Validations
  validates :credentials, presence: { message: "must be specified", on: :create }
  validates_presence_of :cron

  validates_each :credentials, on: :create, allow_blank: true do |job, attr, val|
    username, password = Api.decode_credentials val
    job.errors.add(attr, "are malformed") if username.blank? || password.blank?
  end

  validates_each :steps do |job, attr, value|
    job.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 

  validates_each :cron do |job, attr, value|
    if !value.is_a?(String)
      job.errors.add(attr, 'must be a string')
    else
      value = job.resolve_aliases(value)
      if value.split(' ').length != 5
        job.errors.add(attr, 'must have five components (m h dm m dw)')
      else
        value.split(' ').each_with_index do |component, i|
          job.cron_structure[i] = job.parse(component, CRON_DATA[i])
          job.validate_cron_field job, job.cron_structure[i], component, CRON_DATA[i]
        end
      end
    end
  end


  def resolve_aliases (str)
    return "0 * * * *" if str == "@hourly"
    return "0 0 * * *" if str == "@daily"
    return "0 0 * * 0" if str == "@weekly"
    return "0 0 1 * *" if str == "@monthly"
    return "0 0 1 1 *" if str == "@yearly"
    return "0 0 1 1 *" if str == "@annually"
    str
  end


  def validate_cron_field (cj, cs, component, cron_data)
    return if cs == true
    name = cron_data[:name]
    min, max = cron_data[:range]
    cj.errors.add(:cron, "#{name} value '#{component}' is unrecognized") and return if cs[:unrecognized]
    if cs[:exactly] && (cs[:exactly] < min || cs[:exactly] > max)
      cj.errors.add(:cron, "#{name} value '#{component}' is out of range")
    end
    if cs[:range] && cs[:range][0] < min
      cj.errors.add(:cron, "#{name} range value '#{component}' starts out of range")
    end
    if cs[:range] && cs[:range][1] > max
      cj.errors.add(:cron, "#{name} range value '#{component}' ends out of range")
    end
    if cs[:range] && cs[:range][0] > cs[:range][1]
      cj.errors.add(:cron, "#{name} range value '#{component}' ends before it starts")
    end
    if cs[:member] && cs[:member].any? { |v| v < min || v > max }
      cj.errors.add(:cron, "#{name} list '#{component}' contains out of range element(s)")
    end
  end


  def parse (str, data)
    return true if str == '*'
    if data[:list]
      lb = data[:list_base]
      data[:list].each_with_index do |x, i|
        str = str.gsub x, (lb + i).to_s
      end
    end
    str = str.gsub '*', "#{data[:range][0]}-#{data[:range][1]}"
    if m = str.match("^[0-9]+$")
      { exactly: m[0].to_i }
    elsif m = str.match("^([0-9]+)-([0-9]+)$")
      { range: [m[1].to_i, m[2].to_i] }
    elsif m = str.match("^([0-9]+)-([0-9]+)/([0-9]+)$")
      { range: [m[1].to_i, m[2].to_i], interval: m[3].to_i }
    elsif str =~ /^([0-9]+,)+[0-9]+$/
      { member: str.split(',').map(&:to_i) }
    else
      { unrecognized: str }
    end
  end


  def minutes
    cron_structure[0]
  end
  
  def hours
    cron_structure[1]
  end
  
  def day_of_month
    cron_structure[2]
  end
  
  def month
    cron_structure[3]
  end
  
  def day_of_week
    cron_structure[4]
  end
  

end
