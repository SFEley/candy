# From: http://redcorundum.blogspot.com/2006/05/kernelqualifiedconstget.html
# We need this to properly handle namespaced class resolution in Candy::Wrapper.unwrap.

module Kernel
  def qualified_const_get(str)
    path = str.to_s.split('::')
    from_root = path[0].empty?
    if from_root
      from_root = []
      path = path[1..-1]
    else
      start_ns = ((Class === self)||(Module === self)) ? self : self.class
      from_root = start_ns.to_s.split('::')
    end
    until from_root.empty?
      begin
        return (from_root+path).inject(Object) { |ns,name| ns.const_get(name) }
      rescue NameError
        from_root.delete_at(-1)
      end
    end
    path.inject(Object) { |ns,name| ns.const_get(name) }
  end
end