# frozen_string_literal: true
FactoryGirl.define do
  factory :post do
    title "This is a post"
    body "It has a lot of content"
    association :author, factory: :user
  end
end
