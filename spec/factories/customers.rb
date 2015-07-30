# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :customer do
    firstname "Emer"
    lastname "Rackowski"
    email "erack@mail.com"
    phone "333-444-5555"
    mobile "666-777-8888"
    address_1 "1 East Haskins Road"
    city "Nelson"
    state "NH"
    zip "03457-4555"
  end
end
