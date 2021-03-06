# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Stories API', type: :request do
  let(:faver) do
    FactoryGirl.create(
      :user,
      id: 'de305d54-75b4-431b-adb2-eb6b9e546014',
      username: 'faver',
      profile_picture_url: 'http://a.com/b.jpg'
    )
  end

  before do
    # data integrity
    Story.delete_all
  end

  describe 'get list of stories' do
    context 'unauthenticated' do
      context 'no open stories' do
        it 'is successful' do
          get '/a/v1/me/stories',
              nil

          expect(response.status).to eq(200)
          expect(json['stories']).to eq([])
        end
      end

      context 'one open story' do
        before { faver }
        before do
          FactoryGirl.create(:open_story,
                             id: '123e4567-e89b-12d3-a456-426655440000',
                             faver_id: faver.id,
                             content_url: 'http://a.com/b',
                             title: 'A headline',
                             image_url: 'http://a.com/i.jpg')
        end

        it 'is successful' do
          get '/a/v1/me/stories',
              nil

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(1)

          story = json['stories'].first
          expect(story['id']).to eq('123e4567-e89b-12d3-a456-426655440000')
          expect(story['content_url']).to eq('http://a.com/b')
          expect(story['title']).to eq('A headline')
          expect(story['image_url']).to eq('http://a.com/i.jpg')
          expect(story['published_at']).to be_a(Integer)
          expect(story['faved_at']).to be_a(Integer)
          expect(story['views_count']).to be(0)

          expect(story['faver']['id'])
            .to eq('de305d54-75b4-431b-adb2-eb6b9e546014')
          expect(story['faver']['username']).to eq('faver')
          expect(story['faver']['profile_picture_url'])
            .to eq('http://a.com/b.jpg')
        end
      end

      # rubocop:disable Rails/Date
      context 'many open stories' do
        let(:oldest_id) { Cequel.uuid(Time.zone.now - 1.month) }
        let(:middle_id) { Cequel.uuid(Time.zone.now - 1.week) }
        let(:newest_id) { Cequel.uuid(Time.zone.now) }

        before do
          [newest_id, oldest_id, middle_id].each do |i|
            FactoryGirl.create(
              :open_story,
              faver_id: faver.id,
              id: i,
              faved_at: i.to_time
            )
          end
        end

        it 'is paginated by last_id' do
          get "/a/v1/me/stories?last_id=#{middle_id}",
              nil

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(1)
          expect(json['stories'][0]['id']).to eq(oldest_id.to_s)
        end

        it 'is limited to 20' do
          21.times do
            FactoryGirl.create(
              :open_story,
              faver_id: faver.id
            )
          end

          get '/a/v1/me/stories',
              nil

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(20)
        end
      end
    end

    context 'authorized' do
      let(:user) do
        FactoryGirl.create(
          :user,
          id: '4f16d362-a336-4b12-a133-4b8e39be7f8e',
          email: 'a@user.com',
          authentication_token: 'validtoken'
        )
      end

      before do
        user
        faver
      end

      context 'no stories' do
        it 'is successful' do
          get '/a/v1/me/stories',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['stories']).to eq([])
        end
      end

      context 'one story' do
        before do
          FactoryGirl.create(
            :story,
            c_user: user.in_cassandra,
            id: Cequel.uuid('123e4567-e89b-12d3-a456-426655440000'),
            faver_id: Cequel.uuid('de305d54-75b4-431b-adb2-eb6b9e546014'),
            content_url: 'http://a.com/b',
            title: 'A headline',
            image_url: 'http://a.com/i.jpg'
          )
        end

        it 'is successful' do
          get '/a/v1/me/stories',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(1)

          story = json['stories'].first
          expect(story['id']).to eq('123e4567-e89b-12d3-a456-426655440000')
          expect(story['content_url']).to eq('http://a.com/b')
          expect(story['title']).to eq('A headline')
          expect(story['image_url']).to eq('http://a.com/i.jpg')
          expect(story['published_at']).to be_a(Integer)
          expect(story['faved_at']).to be_a(Integer)
          expect(story['views_count']).to be(0)

          expect(story['faver']['id'])
            .to eq('de305d54-75b4-431b-adb2-eb6b9e546014')
          expect(story['faver']['username']).to eq('faver')
          expect(story['faver']['profile_picture_url'])
            .to eq('http://a.com/b.jpg')
        end
      end

      context 'many stories' do
        let(:oldest_id) { Cequel.uuid(Time.zone.now - 1.month) }
        let(:middle_id) { Cequel.uuid(Time.zone.now - 1.week) }
        let(:newest_id) { Cequel.uuid(Time.zone.now) }

        before do
          Story.delete_all
          [newest_id, oldest_id, middle_id].each do |i|
            FactoryGirl.create(
              :story,
              c_user: user.in_cassandra,
              faver_id: Cequel.uuid('de305d54-75b4-431b-adb2-eb6b9e546014'),
              id: i
            )
          end
        end

        it 'is paginated by last_id' do
          get "/a/v1/me/stories?last_id=#{middle_id}",
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(1)
          expect(json['stories'][0]['id']).to eq(oldest_id.to_s)
        end

        it 'is limited to 20' do
          21.times do
            FactoryGirl.create(
              :story,
              c_user: user.in_cassandra,
              faver_id: Cequel.uuid('de305d54-75b4-431b-adb2-eb6b9e546014')
            )
          end

          get '/a/v1/me/stories',
              nil,
              'X-Email' => 'a@user.com',
              'X-Auth-Token' => 'validtoken'

          expect(response.status).to eq(200)
          expect(json['stories'].size).to eq(20)
        end
      end
    end
  end
end
