# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cron_job do
    credentials "bWFnbmV0bzp4YXZpZXI="
    cron        "* * * * *"
  end
end
