module Book
  class InflectedForm
    include DataMapper::Resource
    
    property :id, Serial
    property :variant, String, :nullable => false
    
    belongs_to :definition
  
  end
end # Dictionary
