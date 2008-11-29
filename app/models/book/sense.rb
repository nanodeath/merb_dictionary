module Book
  class Sense
    include DataMapper::Resource
    
    property :id, Serial
    property :value, String, :nullable => false
    property :synonym, String
    property :example, String
    
    belongs_to :sense_group
  
  end
end # Dictionary
