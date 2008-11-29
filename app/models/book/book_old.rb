require 'nokogiri'
require 'open-uri'
require 'facets'

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
      
      puts "entry is #{entry}"
      
      sense_count = 0
      senses = []
      label = nil
      subsense = nil
      content = ''
      
      entry.css('.defs span').each do |span|
        classes = span.attributes['class'].nil? ? [] : span.attributes['class'].strip.split;
        if(classes.include? 'sense_break')
          sense_count += 1
          #puts " * sense_break #{span}"
        elsif(classes.include? 'sense_label')
          #puts " * sense_label: #{span}"
          if label.nil?
            label = span.inner_text.split # could be ["1"], or ["1", "a"]
            #puts "split label is #{label}"
            if label.count > 1
              #puts "count > 1: #{label.join('::')}"
              label = label.last
              subsense = nil
            elsif is_letter?(label.first)
              label = label.first
            #elsif !subsense.nil?
              #puts "found subsense, label was #{label.join('::')}"
            #  label = subsense
            else
              label = ''
            end
          end
        elsif(classes.include? 'sense_content')
          #puts " * sense_content"
          if(!subsense.nil?)
            puts "subsense is not nil, so adding #{label} and #{subsense} together"
            label += ' ' + subsense
            subsense = nil
            label.strip!
          end
        
          content = span.inner_text.lchomp(':').strip # could be [":", "presence", ",", "sight"]
          example = content.index('<')
          unless example.nil?
            content, example = content[0..example-1].strip, content[example+1..(content.length-2)].strip
          end
          content = content.compress_lines.split(':')
          content, synonym = content[0], content[1]
          
          puts "sense_count: #{sense_count}, label: #{label}, content: #{content}"
          unless example.nil?
            puts " - example is #{example}"
          end
          unless synonym.nil?
            synonym.strip!
            puts " - synonym is #{synonym}"
          end
          label = nil
        elsif(classes.empty?)
          subsense = span.css('.subsense').inner_text.strip
          subsense = subsense[1..(subsense.length-2)]
          puts "found subsense: #{subsense}"
        end
      end
      
      puts "word is #{word}, syllables is #{syllables}, has_variants is #{has_variants}, pron is #{pron}, function is #{function}"
      puts "etymology is #{etymology}"
      puts "date is #{date}"
      puts "senses is #{senses.to_s}"
      
    end
    
    private
    
    def MerriamWebster.is_letter?(str)
      !(str =~ /^[a-zA-Z]$/).nil?
    end
  end
end