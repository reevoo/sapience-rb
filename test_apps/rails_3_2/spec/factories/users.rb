# frozen_string_literal: true
FactoryGirl.define do
  sequence(:username) { |i| "mrcool#{i}" }
  sequence(:email) { |i| "so#{i}@cool.com" }
  factory :user do
    username
    email
  end
end
