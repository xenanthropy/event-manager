# frozen-string-literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  parsed_number = phone_number.delete('.').delete(' ').delete('-').delete('(').delete(')')
  if parsed_number.length < 10 || (parsed_number.length == 11 && parsed_number[0] != '1') || parsed_number.length > 11
    'bad number!'
  elsif parsed_number.length == 11 && parsed_number[0] == '1'
    parsed_number[1..phone_number.length - 1]
  else
    parsed_number
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def best_day(date_array)
  date_hash = Hash.new(0)
  date_array.each do |date|
    split_date = date.split('/')
    date = split_date.unshift(split_date.pop).join('/')
    date_hash[date] += 1
  end
  biggest = 0
  best_weekday = []
  date_hash.each { |_key, value| biggest = value if value > biggest }
  best_day_array = date_hash.select { |_key, value| value == biggest }.keys
  best_day_array.each { |date| best_weekday << Date.parse(date).wday }
  convert_weekday(best_weekday)
end

def convert_weekday(best_weekday)
  days = []
  best_weekday.each do |day|
    case day
    when 0
      days << WEEKDAY_NAMES[0]
    when 1
      days << WEEKDAY_NAMES[1]
    when 2
      days << WEEKDAY_NAMES[2]
    when 3
      days << WEEKDAY_NAMES[3]
    when 4
      days << WEEKDAY_NAMES[4]
    when 5
      days << WEEKDAY_NAMES[5]
    when 6
      days << WEEKDAY_NAMES[6]
    end
  end
  days
end

def best_time(time_array)
  time_hash = Hash.new(0)
  time_array.each do |time|
    hour = time.split(':')[0]
    time_hash[hour] += 1
  end
  biggest = 0
  time_hash.each { |_key, value| biggest = value if value > biggest }
  time_hash.select { |_key, value| value == biggest }.keys
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb') if File.exist?('form_letter.erb')
erb_template = ERB.new template_letter

if File.exist?('event_attendees.csv')
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

time_array = []
date_array = []

contents.each_with_index do |row, index|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  time_date = row[:regdate].to_s.split(' ')
  date_array << time_date[0]
  time_array << time_date[1]

  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end
puts "the most popular hour/s: #{best_time(time_array)}"
puts "the most popular weekday/s: #{best_day(date_array)}"
