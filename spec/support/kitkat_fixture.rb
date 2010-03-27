# An example class to be embedded in another
class KitKat
  include Candy::Piece
end

class KitKats
  include Candy::Collection
  collects :kit_kat
end

