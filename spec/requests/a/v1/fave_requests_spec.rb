# frozen_string_literal: true
require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe 'Fave API', type: :request do
  context 'unauthenticated' do
    it 'is unauthorized' do
      get '/a/v1/fave'

      expect(response.status).to eq(401)
      expect(json['errors']).to_not be_blank
    end
  end

  context 'authorized' do
    let(:user) do
      FactoryGirl.create(
        :user,
        id: 'de305d54-75b4-431b-adb2-eb6b9e546014',
        email: 'a@user.com',
        username: 'user',
        authentication_token: 'validtoken'
      )
    end

    before do
      3.times do
        FactoryGirl.create(:follower,
                           c_user: user.in_cassandra)
      end
    end

    it 'is successful' do
      Sidekiq::Testing.inline! do
        expect(Story.count).to eq(0)
        expect(user.in_cassandra.followers.count).to eq(3)

        # Workaround to assert counter increment
        expect_any_instance_of(Cequel::Metal::DataSet).to receive(:increment)
          .with(faves: 1)

        expect do
          get '/a/v1/fave?url=http://example.com/hello?source=xyz',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'
        end.to change(CUserFave, :count).by(1)

        expect(response.status).to eq(200)

        expect(Story.count).to eq(4)
      end
    end

    context 'invalid' do
      it 'is unprocessable entity' do
        get '/a/v1/fave?url=x.com',
            nil,
            'X-Email' => 'a@user.com',
            'X-Auth-Token' => 'validtoken'
        expect(response.status).to eq(422)
      end
    end
  end
end
