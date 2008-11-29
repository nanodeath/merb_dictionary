module Book
  class Definition
    include DataMapper::Resource
    
    property :id, Serial
    property :word, String, :nullable => false
    property :pronunciation, String
    property :function, String, :nullable => false
    property :etymology, Text
    property :date, String
    
    has n, :inflected_forms
    has n, :sense_groups
  
  end
end # Dict
