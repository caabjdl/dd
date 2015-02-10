json.phone @phone
json.workers @aa_workers do |aa_worker|
  json.id aa_worker.id
  json.name aa_worker.name
end
json.trailers @aa_trailers do |aa_trailer|
  json.id aa_trailer.id
  json.license_no aa_trailer.license_no
end
