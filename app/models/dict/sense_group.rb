module Dict
  class SenseGroup
    include DataMapper::Resource
    
    property :id, Serial
    property :type, Enum[:none, :transitive, :intransitive], :default => :none
    
    belongs_to :definition
    has 1..n, :senses
  
  end
end # Dictionary
