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
    attribute :seconds,              :serialized, default: nil
    attribute :minutes,              :serialized, default: nil
    attribute :hours,                :serialized, default: nil
    attribute :day_of_month,         :serialized, default: nil
    attribute :month,                :serialized, default: nil
    attribute :day_of_week,          :serialized, default: nil
  end
  

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
    c = cron.split(' ')
    self.seconds = c[0] 
    self.minutes = c[1] 
    self.hours = c[2] 
    self.day_of_month = c[3] 
    self.month = c[4] 
    self.day_of_week = c[5]
  end

end
