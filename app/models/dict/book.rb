require 'nokogiri'
require 'open-uri'

module Dict
  class Book

    def Book.lookup(word)
      d = Definition.first(:word => word)
      return d unless d.nil?
      
      puts "looking up word:"
      MerriamWebster.lookup(word)
    end
  end
  
  class MerriamWebster
    def MerriamWebster.lookup(word)
      doc = Nokogiri::HTML(open("http://www.merriam-webster.com/dictionary/#{word}"))
      
      entry = doc.css('div.word_definition div.entry')
      
      word = entry.css('dd.hwrd span.variant')
      has_variants = word.css('sup') != ''
      word.css('sup').remove
      word = word.inner_text
      
      syllables = word.count('·')/2 + 1 #er, yes...it's weird
      word.gsub!(/·/, '')
      
      pron = entry.css('dd.pron').inner_text.strip
      
      function = entry.css('dd.func em').inner_text.strip
      
      etymology = entry.css('dd.ety').inner_text.strip # might be ""
      
      date = entry.css('dd.date').inner_text.strip
      
      senses = entry.css('.sense_break')
      
      puts "word is #{word}, syllables is #{syllables}, has_variants is #{has_variants}, pron is #{pron}, function is #{function}"
      puts "etymology is #{etymology}"
      puts "date is #{date}"
      puts "senses is #{senses.to_s}"
      
    end
  end
end