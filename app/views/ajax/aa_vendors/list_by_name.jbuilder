json.array! @aa_vendors do |vendor|
  json.id vendor[0]
  json.no vendor[1]
  json.name vendor[2]
  json.aa_vendor_type vendor[3]
end