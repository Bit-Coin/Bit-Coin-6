# RadarChart.js data format
# http://bl.ocks.org/nbremer/6506614#RadarChart.js

json.array! @series do |series|
  json.array! series[:scores] do |score|
    json.axis     score.characteristic.name[0..3]
    json.value    '%.2f' % score.mean.to_f
  end
end
