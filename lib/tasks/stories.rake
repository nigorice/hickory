namespace :stories  do
  task seed: :environment do
    print 'Create stories for username: '
    username = $stdin.gets.chomp.strip.to_s

    user = User.find_by_username(username)
    unless user
      fail("No User with username: #{username}")
    end

    target = FactoryGirl.create(:user)
    print "#{user.username} following #{target.username}\n"
    FollowUserWorker.new.perform(user.id.to_s, target.id.to_s)

    articles = Content.limit(50).to_a
    if articles.empty?
      fail('No articles available')
    end

    articles.each do |a|
      FaveWorker.new.perform(target.id.to_s, a.url, rand(900).minutes.ago.to_s)
    end

    print "Success! #{user.username} should have #{articles.size} additional stories now. Don't forget to start sidekiq.\n"
  end
end
