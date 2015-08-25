json.user do
  json.id @user.id
  json.username @user.username
  json.full_name @user.full_name
  json.description @user.description
  
  json.recent_faves(@recent_faves) do |fave|
    json.id                     fave.id.to_s
    json.content_url            fave.content_url
    json.title                  fave.title
    json.image_url              fave.image_url
    json.published_at           fave.published_at.to_i
    json.faved_at               fave.faved_at.to_i
  end
end
