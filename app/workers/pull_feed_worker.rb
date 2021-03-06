# frozen_string_literal: true
class PullFeedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pull_feed

  def perform(feeder_id)
    feeder = Feeder.find(feeder_id)
    response = Typhoeus.get(feeder.feed_url,
                            timeout: 5,
                            followlocation: true,
                            accept_encoding: 'gzip')
    feed = Feedjira::Feed.parse(response.body)

    feeder.top_articles.delete_all

    populate_articles(feeder, feed)

    PullFeedWorker.perform_in(5.minutes, feeder_id)
  end

  private

  def populate_articles(feeder, feed)
    feed.entries.each do |entry|
      feeder.top_articles.create!(
        content_url: Fave::Url.new(entry.url).canon,
        title: entry.title, image_url: get_image_url(entry),
        published_at: entry.published
      )
    end
  end

  # TODO: untested
  def get_image_url(entry)
    # NOTE: nil is an acceptable return value
    # but try statements should be used with caution
    entry.try(:image) || entry.try(:enclosure_url) || parse_image_url(entry)
  end

  # TODO: untested
  def parse_image_url(entry)
    img = Nokogiri::HTML(entry.content).xpath('//img').first

    return img['src'] if img

    nil
  end
end
