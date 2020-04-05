# typed: ignore

def duck(interface_name, method_name, &blk); end

module Duck
  def self.const_missing(*)
    Object
  end
end
