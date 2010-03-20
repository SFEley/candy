# An example class to contain our methods
class Zagnut
  include Candy::Piece
end

class Zagnuts
  include Candy::Collection
  
  collects :zagnut
end
