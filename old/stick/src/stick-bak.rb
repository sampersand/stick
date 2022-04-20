class Parser:Object
  Block = Struct.new(:body);

  Array private attr :stream;
  String private attr :current;

  def initialize(input=String)
    self.stream = input.split();
  end

  String private def shiftFromStream()
    self.current = self.stream.shift()
  end

  

end
__END__
class Parser
  Block = Struct.new :"body"

  attr(:stream, true)

  def initialize input
    self.stream = input.split($;);
  end

  def shiftFromStream(*)
    $current = stream().shift();
  end

  def removeCommentFromStream()
    n = 1;
    begin
      self::shiftFromStream().nil? and throw("unclosed right paren encountered!")
      $current == '(' and n += 1;
      $current == ')' and n -= 1;
    end while (!n.equal?(0));
  end

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
