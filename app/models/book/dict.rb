require 'nokogiri'
require 'open-uri'
require 'facets'

module Book
  class Dict

    def Dict.lookup(word)
      d = Definition.first(:word => word)
      return d unless d.nil?
      
      puts "looking up word:"
      MerriamWebster.lookup(word)
    end
  end
  
  class MerriamWebster < Dict
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
      labels = []
      all_labels = {}
      content = ''
      
      entry.css('.defs span').each do |span|
        next if !span.parent.attributes['class'].nil? and span.parent.attributes['class'].strip.split.include? 'variant'
        classes = span.attributes['class'].nil? ? [] : span.attributes['class'].strip.split;
        if(classes.include? 'sense_break')
          sense_count += 1
          #puts " * sense_break #{span}"
        elsif(classes.include? 'sense_label')
          #puts " * sense_label: #{span}"
          label = span.inner_text.split # could be ["1"], or ["1", "a"]
            if label.count > 1
              
              labels = []
              labels[0], labels[1] = label[0], label[1]
              labels[0] = {:num => labels[0]}
            elsif is_letter?(label.first)
              labels[1] = label.first
              labels.delete_at(2)
            elsif is_number?(label.first)
              #puts "resetting labels2"
              labels = []
              labels[0] = label.first
              labels[0] = {:num => labels[0]}
            elsif(classes.include? 'subsense') # like (1)
              labels[2] = label.first[1].chr
            end
        elsif(classes.include? 'sense_content')
          #puts " * sense_content"
        
          content = span.inner_text.lchomp(':').strip # could be [":", "presence", ",", "sight"]
          example = content.index('<')
          unless example.nil?
            content, example = content[0..example-1].strip, content[example+1..(content.length-2)].strip
          end
          puts "content: presplit: #{content}"
          content_last = content[-1].chr
          content = content.compress_lines.split(':')
          content, synonym = content[0], content[1]
          content = content.strip unless content.nil?
          synonym = synonym.strip unless synonym.nil?
          
          
          puts "sense_count: #{sense_count}, label: #{labels.nil? ? '' : labels.join(':')}, content: #{content}"
          #all_labels[labels.clone] = content
          #labels.map! {|l| l.to_s }
          if content_last == ':'
            #content_last = nil
            #labels[0] += ':' + content
            #labels[0][:type] = content
            #puts "labels[0] is #{labels[0].inspect}, labels[1] is #{labels[1]}, and content is #{content.inspect}"
            #labels[1]
            #labels[1] = :defn
            #content[:defn] = content
          end  
           
          
          if labels.length > 0
            all_labels[labels[0]] ||= {}
          end
          if labels.length > 1
            all_labels[labels[0]][labels[1]] ||= {}
          end
          if labels.length > 2
            begin
              all_labels[labels[0]][labels[1]][labels[2]] = ''
            rescue
              #puts "labels 0, 1: #{labels[0]}; #{labels[1]}"
              #puts "currently: " + all_labels[labels[0].to_s]
              all_labels[labels[0]] = {}
              all_labels[labels[0]][labels[1]] = {}
              retry
            end
          end
          #puts "labels: #{labels.join(':')}"
          content = {:defn => content}
          content[:example] = example unless example.nil?
          content[:synonym] = synonym unless synonym.nil?
          
          if labels.count == 1
            all_labels[labels[0]] = content
          end
          if labels.count == 2
            all_labels[labels[0]][labels[1]] = content
          end
          if labels.count == 3
            all_labels[labels[0]][labels[1]][labels[2]] = content
          end
          
          unless example.nil?
            puts " - example is #{example}"
          end
          unless synonym.nil?
            synonym.strip!
            puts " - synonym is #{synonym}"
          end
        elsif(classes.empty?)
          subsense = span.css('.subsense').inner_text.strip
          subsense = subsense[1..(subsense.length-2)]
          labels[2] = subsense
          #puts "found subsense: #{subsense}"
        end
      end
      
      puts "word is #{word}, syllables is #{syllables}, has_variants is #{has_variants}, pron is #{pron}, function is #{function}"
      puts "etymology is #{etymology}"
      puts "date is #{date}"
      
      require 'pp'
      pp all_labels
    end
    
    private
    
    def MerriamWebster.is_letter?(str)
      !(str =~ /^[a-zA-Z]$/).nil?
    end
    
    def MerriamWebster.is_number?(str)
      !(str =~ /^[0-9]$/).nil?
    end
  end
end