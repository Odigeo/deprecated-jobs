# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :async_job do
    credentials "bWFnbmV0bzp4YXZpZXI="
    token       "A-totally-fake-token"
  end
end
