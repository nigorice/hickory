# frozen_string_literal: true
FactoryGirl.define do
  factory :featured_user do
    association :user, factory: :user, strategy: :build
  end
end
