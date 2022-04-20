#!ruby -wanF(?=) -rstringio
END{p$=.length==26}
BEGIN { $stdin=StringIO.new "abcdefghijklmnopqrstuvwxyz"; alias $= $-_ }

begin
  $DEBUG,=private_methods.grep %r/#{$F.sort[7].upcase}/o
  $=||=eval "#$-d[]"
rescue Exception
  exit 0
end
eval <<RUBY or next unless $F.one?
BEGIN {
  class << ($stdin=*$F)
    alias gets shift
  end
}
RUBY
$=[$_]||=!/#{$=.length.chr}/i



# def($stdin=p).gets =p

__END__
p $-d
exit
global_variables.each do |v|
  puts v
  # puts "#{v}=#{eval(v.to_s).inspect}"
  # eval "begin #{v}={}; STDIN.puts #{v.inspect}; rescue Exception; end "
rescue Exception
end
__END__
$F.each_cons 2 do |a,b|
  p [a, b]
end

__END__

p $F.map(&:ord).pack('C*').unpack('S*')
for x in 'a'..'z'
  puts x.ord.to_s 2
end
puts
for x in 'A'..'Z'
  puts x.ord.to_s 2
end

@a=$F
$F
  # while 
  # "abcdefghijklmnopqrstuvwxyz"
  p gets
# end



# require 'benchmark'
# Benchmark.bmbm do |bm|
#   bm.report("adding") { 100000.times { "A" + "B" } }
#   bm.report("concat") { 100000.times { "A".concat "B" } }
# end

__END__
def Void(_) end # make it so you can call methods void.
def Object(_) end # make it so you can just return an object.

class Parser:Object
  Array private attr :stream, true;
  String private attr :current, true;

  Void def initialize(input=String)
    self.stream = input.split();
  end

  String private def shiftFromStream()
    self.current = self.stream.shift();
    return self.current;
  end

  Void def removeCommentFromStream()
    Integer n = 1;

    while (n != 0) do
      if (self.shiftFromStream() == nil) then
        throw Exception.new("unclosed right paren encountered!");
      else if (self.current == '(') then
        n += 1;
      else if (self.current == ')') then
        n -= 1;
      end end end
    end

    return;
  end

  def parse()
    else if not (integer=Integer($current) rescue nil).nil?{} then
      returnValue = integer;
  end

  Object def next()
    Object returnValue = nil;

    if (self.shiftFromStream() == nil) then
      # do nothing
    else if ((num = Parser::parse_integer($current)))

    end end
  end
end

p = Parser.new(%|{ x "X" 1 }|).next
__END__

  def next()
    returnValue = nil;
    if self::shiftFromStream().nil?{}
      # do nothing!

    else if not (integer=Integer($current) rescue nil).nil?{} then
      returnValue = integer;

    else if ($current[0] == '"' && $current[$current.length-1] == '"') then
      $current[-1, 1] = $current[0, 1] = "";
      returnValue = $current.gsub('\s', ?\s)

    else if ($current == '(') then
      self.removeCommentFromStream()
      returnValue = self.next()

    else if $current == '{' then
      returnValue = Block::new ary=[];
      (
        $tmp.nil?() and throw("unclosed right paren");
        ary.push $tmp;
      ) until ($tmp=self.next()) === :'}';

    else returnValue = :"#$current"end;end;end;end;end # :-(

    return(returnValue);
  end
end


p Parser.new("{ 123 \"123\" q ( L ) } b c").next
