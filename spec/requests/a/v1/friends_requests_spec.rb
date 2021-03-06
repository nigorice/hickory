# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'On-boarding Friends API', type: :request do
  describe 'get list of friends' do
    context 'unauthenticated' do
      it 'is empty' do
        get '/a/v1/friends'

        expect(response.status).to eq(200)
        expect(json['friends']).to eq([])
      end
    end

    context 'authenticated' do
      let(:user) do
        FactoryGirl.create(
          :user,
          id: '4f16d362-a336-4b12-a133-4b8e39be7f8e',
          email: 'a@user.com',
          authentication_token: 'validtoken'
        )
      end

      let(:friend) do
        FactoryGirl.create(
          :user,
          id: 'de305d54-75b4-431b-adb2-eb6b9e546014',
          username: 'friend',
          full_name: 'John Doe'
        )
      end

      before { user }
      before { friend }

      context 'no friends' do
        before { Friend.delete_all }

        it 'is successful' do
          get '/a/v1/friends',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['friends']).to eq([])
        end
      end

      context 'one friend' do
        before do
          FactoryGirl.create(
            :friend,
            c_user: user.in_cassandra,
            id: friend.id.to_s
          )
        end

        it 'is successful' do
          get '/a/v1/friends',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['friends'].size).to eq(1)

          friend = json['friends'].first
          expect(friend['id']).to eq('de305d54-75b4-431b-adb2-eb6b9e546014')
          expect(friend['username']).to eq('friend')
          expect(friend['full_name']).to eq('John Doe')
        end
      end

      context 'many friends' do
        let(:oldest_id) { Cequel.uuid(Time.zone.now - 1.month) }
        let(:middle_id) { Cequel.uuid(Time.zone.now - 1.week) }
        let(:newest_id) { Cequel.uuid(Time.zone.now) }

        before do
          Friend.delete_all
          [newest_id, oldest_id, middle_id].each do |i|
            FactoryGirl.create(
              :user,
              id: i.to_s
            )
            FactoryGirl.create(
              :friend,
              c_user: user.in_cassandra,
              id: i
            )
          end
        end

        it 'is paginated by last_id' do
          get "/a/v1/friends?last_id=#{middle_id}",
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['friends'].size).to eq(1)
          expect(json['friends'][0]['id']).to eq(newest_id.to_s)
        end

        it 'is limited to 20' do
          21.times do |i|
            u = FactoryGirl.create(
              :user,
              username: 'user_' + i.to_s
            )
            FactoryGirl.create(
              :friend,
              c_user: user.in_cassandra,
              id: u.id
            )
          end

          get '/a/v1/friends',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['friends'].size).to eq(20)
        end
      end
    end
  end
end
