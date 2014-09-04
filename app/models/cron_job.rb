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
    attribute :cron_structure,       :serialized, default: [nil, nil, nil, nil, nil, nil]
  end

  CRON_DATA = [
    {name: "seconds",       range: [0, 59]
    },
    {name: "minutes",       range: [0, 59]
    },
    {name: "hours",         range: [0, 23]
    },
    {name: "day_of_month",  range: [1, 31]
    },
    {name: "month",         range: [1, 12], list: %w(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC) 
    },
    {name: "day_of_week",   range: [0, 6], list: %w(SUN MON TUE WED THU FRI SAT)
    }
  ]
  

  # Validations
  validates :credentials, presence: { message: "must be specified", on: :create }
  validates_presence_of :cron

  validates_each :credentials, on: :create, allow_blank: true do |job, attr, val|
    username, password = Api.decode_credentials val
    job.errors.add(attr, "are malformed") if username.blank? || password.blank?
  end

  validates_each :steps do |record, attr, value|
    record.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 

  validates_each :cron do |record, attr, value|
    if !value.is_a?(String)
      record.errors.add(attr, 'must be a string')
    else
      record.errors.add(attr, 'must have six components') if value.split(' ').length != 6
    end
  end


  # Callbacks
  before_save do |cj|
    cron.split(' ').each_with_index do |component, i|
      self.cron_structure[i] = parse(component, CRON_DATA[i])
    end
  end


  def parse (str, data)
    if str == '*'
      { range: data[:range] }
    elsif m = str.match("^[0-9]+$")
      { exactly: m[0].to_i }
    elsif m = str.match("^([0-9]+)-([0-9]+)$")
      { range: [m[1].to_i, m[2].to_i] }
    elsif m = str.match("^([0-9]+)-([0-9]+)/([0-9]+)$")
      { range: [m[1].to_i, m[2].to_i], interval: m[3].to_i }
    end
  end




  def seconds
    cron_structure[0]
  end
  
  def minutes
    cron_structure[1]
  end
  
  def hours
    cron_structure[2]
  end
  
  def day_of_month
    cron_structure[3]
  end
  
  def month
    cron_structure[4]
  end
  
  def day_of_week
    cron_structure[5]
  end
  

end
