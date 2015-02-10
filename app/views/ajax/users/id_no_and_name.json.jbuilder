json.array! @users do |user|
  json.id user[0]
  json.no user[1]
  json.name user[2]
end