#!/usr/bin/env ruby
require "csv"
require "set"
require "twitter-text"

fwords  = File.read("french-stopwords.csv").downcase.split.reject(&:empty?).to_set
ewords  = File.read("english-stopwords.csv").downcase.split.reject(&:empty?).to_set
french  = CSV.read("french.csv")
english = CSV.read("english.csv")

class String
  def to_words
    self.
      gsub("\n", " ").
      gsub("\r", " ").
      gsub(/[.,]+/, "").
      gsub(/\brt\b/, "").
      downcase.
      gsub(Twitter::Regex[:valid_hashtag], "").
      gsub(Twitter::Regex[:valid_mention_or_list], "").
      gsub(Twitter::Regex[:valid_reply], "").
      gsub(Twitter::Regex[:valid_url], "").
      split(/\b/).
      map(&:strip).
      reject(&:empty?)
  end
end

f, e, u, n = [], [], [], []
(french + english).flatten.shuffle.each do |text|
  words = text.to_words.to_set
  french_score  = (fwords & words).size
  english_score = (ewords & words).size + 1
  f << text if french_score > english_score
  e << text if english_score > french_score
  n << text if french_score.zero? && english_score.zero?
  u << [ french_score, text ] if french_score == english_score && french_score.nonzero?
end

puts "French #{f.size} / #{french.size} = #{f.size.to_f / french.size * 100}"
puts "======"*6
puts f.shuffle.first(20)

puts
puts "English #{e.size} / #{english.size} = #{e.size.to_f / english.size * 100}"
puts "======="*6
puts e.shuffle.first(20)

puts
puts "None #{n.size} / #{french.size + english.size} = #{n.size.to_f / (french.size + english.size) * 100}"
puts "======="*6
puts n.shuffle.first(20)

puts
puts "Unknown #{u.size} / #{french.size + english.size} = #{u.size.to_f / (french.size + english.size) * 100}"
puts "======="*6
u.shuffle.first(20).each do |score, text|
  printf "%2d\t%s\n", score, text
end

puts
words = u.map(&:last).map(&:to_words).inject(&:+)
puts "Unknown words: #{words.uniq.size}"
frequencies = words.each_with_object(Hash.new{|h, k| h[k] = 0}) do |word, memo|
  memo[word] += 1
end

frequencies.sort_by(&:last).reverse.first(30).each do |word, freq|
  printf "%3d: %s\n", freq, word
end
