#!/usr/bin/ruby
class Parser
  def initialize(stream)
    @stream = stream
  end

  def each
    while (x=self.next)
      yield x
    end
  end

  def strip_whitespace!
    @stream.slice! /\A(?:\s+|\#.*?\n)*/
  end

  def next_number
    @stream.slice!(/\A\d+\b/)&.to_i
  end

  def next_string
    if @stream.slice! /\A(['"])((?:\\.|(?!\1).)*)\1/
      $2
    else
      @stream.slice! /\A[\w_]+/
    end
  end

  NULLARY_TOKENS = %w(
    add cat sub mul rep div mod
    eql neq lth gth leq geq
    ret print
  )
  NUMBER_TOKENS = %w(dup pop)
  STRING_TOKENS = %w(fn : jt jf jmp push call)

  def next
    strip_whitespace!
    fn = @stream.slice!(/\A([\w_]+|:)\b/) or return
    strip_whitespace!

    if NULLARY_TOKENS.include? fn
      [fn, nil]
    elsif NUMBER_TOKENS.include? fn
      [fn, next_number || raise("missing argument for '#{fn}'")]
    elsif STRING_TOKENS.include? fn
      [fn, next_string || raise("missing argument for '#{fn}'")]
    else
    raise "unknown function '#{fn}'"
    end
  end
end

class Compiler
  class Function
    def name
      "@#@name"
    end

    def initialize(name)
      @name = name
      @lines = []
      @labels = Hash.new { |h,k| h[k] = next_local }
      @local = 0
    end

    def next_local
      (@local += 1).to_s
    end

    def label(name)
      @labels[name]
    end

    def write(local=false, line)
      if local
        lcl = "%#{next_local}"
        @lines.push "#{lcl} = #{line}"
        lcl
      else
        @lines.push line
      end
    end

    def to_s
      <<~LLVM
        ; define void @_lc_user_#@name() {
        define void @#@name() {
          #{@lines.join("\n  ")}
          ret void
        }
      LLVM
    end
  end

  def initialize(parser)
    @parser = parser
    @functions = Hash.new { |h,k| h[k] = Function.new k }
    @current_function = nil
    @constants = Hash.new { |h, k| h[k] = "@.lc_const_#{h.length}" }
  end

  def self.prelude(nglobals=100000)
    <<~LLVM
      target triple = "arm64-apple-macosx12.0.0"

      %LC_Globals_Type = type [#{nglobals} x i64]
      @lc_globals = common global %LC_Globals_Type zeroinitializer, align 8
      @lc_idx = local_unnamed_addr global i64* getelementptr inbounds (%LC_Globals_Type, %LC_Globals_Type* @lc_globals, i64 0, i64 0), align 8
      @.lc_to_str_str = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
      @lc_to_str.ptrbuf = internal global [40 x i8] zeroinitializer, align 1
      
      declare noundef i32 @puts(i8* nocapture noundef readonly) local_unnamed_addr #2
      declare noundef i64 @strtoll(i8* nocapture noundef readonly, i8**, i32) ; should really be `, i8**`
      declare noalias i8* @strdup(i8* nocapture readonly) local_unnamed_addr #1
      declare noundef i32 @snprintf(i8* noalias nocapture noundef writeonly, i64 noundef, i8* nocapture noundef readonly, ...) local_unnamed_addr #5
      declare noundef i64 @strlen(i8* nocapture) local_unnamed_addr #2
      declare noundef i8* @strcat(i8* noalias returned, i8* noalias nocapture readonly) local_unnamed_addr #3
      declare noalias noundef i8* @malloc(i64) local_unnamed_addr #1


      define i8* @lc_str_cat(i8* nocapture readonly %0, i8* nocapture readonly %1) local_unnamed_addr #0 {
        %3 = tail call i64 @strlen(i8* nonnull dereferenceable(1) %0)
        %4 = tail call i64 @strlen(i8* nonnull dereferenceable(1) %1)
        %5 = add i64 %3, 1
        %6 = add i64 %5, %4
        %7 = tail call i8* @malloc(i64 %6)
        store i8 0, i8* %7, align 1
        %8 = tail call i8* @strcat(i8* nonnull %7, i8* nonnull dereferenceable(1) %0)
        %9 = tail call i8* @strcat(i8* nonnull %7, i8* nonnull dereferenceable(1) %1)
        ret i8* %7
      }

      define noalias i8* @lc_to_str(i64 %0)  {
        %2 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* nonnull dereferenceable(1) getelementptr inbounds ([40 x i8], [40 x i8]* @lc_to_str.ptrbuf, i64 0, i64 0), i64 40, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.lc_to_str_str, i64 0, i64 0), i64 %0)
        %3 = tail call i8* @strdup(i8* getelementptr inbounds ([40 x i8], [40 x i8]* @lc_to_str.ptrbuf, i64 0, i64 0))
        ret i8* %3
      }

      define i64 @lc_to_int(i8* %0) {
        %2 = call i64 @strtoll(i8* nocapture %0, i8** null, i32 10)
        ret i64 %2
      }

      define void @push(i64 %0) {
        %2 = load i64*, i64** @lc_idx
        %3 = getelementptr inbounds i64, i64* %2, i64 1
        store i64* %3, i64** @lc_idx
        store i64 %0, i64* %2
        ret void
      }

      define i64 @pop() {
        %1 = load i64*, i64** @lc_idx
        %2 = getelementptr inbounds i64, i64* %1, i64 -1
        store i64* %2, i64** @lc_idx
        %3 = load i64, i64* %2
        ret i64 %3
      }

      define i32 @main() {
        call void @start()
        %1 = cmp eq i64** @lc_idx, i8* @lc_globals

        %2 = call i64 @pop()
        %3 = inttoptr i64 %2 to i8*
        %4 = call i64 @lc_to_int(i8* %3)
        %5 = trunc i64 %4 to i32
        ret i32 %5
      }
    LLVM
  end

  def constants_str
    @constants
      .map {|value, name| %(#{name} = private unnamed_addr constant [#{value.length + 1} x i8] c"#{value}\0", align 1)}
      .join("\n")
  end

  def to_s
    Compiler::prelude + "\n" + constants_str + "\n\n" + @functions.values.join("\n")
  end

  def current_function
    @functions[@current_function]
  end

  def write(*a)
    current_function.write(*a)
  end

  def compile
    @parser.each do |token|
      compile_token token
    end
  end

  def ptrtoint(ptr)
    write true, "ptrtoint i8* #{ptr} to i64"
  end

  def inttoptr(ptr)
    write true, "inttoptr i64 #{ptr} to i8*"
  end

  def pop
    write true, "call i64 @pop()"
  end

  def push(value)
    write "call void @push(i64 #{value})"
  end

  def convert_to_int(value)
    write true, "call i64 @lc_to_int(i8* #{value})"
  end

  def convert_to_str(value)
    write true, "call i8* @lc_to_str(i64 #{value})"
  end

  def compile_token(token)
    kind, value = token

    case kind
    when 'fn' then @current_function = value
    when 'call' then write "call void #{@functions[value].name}()"
    when 'ret' then write 'ret void'
    when ':' then write ".#{current_function.label value}:"
    when 'jmp' then write "br label %.#{current_function.label value}"

    when 'push' 
      value = value
      kind = "[#{value.length + 1} x i8]"
      name = @constants[value]

      ptr = write true, "getelementptr inbounds #{kind}, #{kind}* #{name}, i64 0, i64 0"
      push ptrtoint ptr
      
    when 'pop' then raise
    when 'add'
      lhs = convert_to_int inttoptr pop
      rhs = convert_to_int inttoptr pop
      push ptrtoint convert_to_str write true, "add i64 #{lhs}, #{rhs}"

    when 'cat'
      lhs = inttoptr pop
      rhs = inttoptr pop
      push ptrtoint write true, "call i8* @lc_str_cat(i8* #{lhs}, i8* #{rhs})"

    when 'sub'
      lhs = convert_to_int inttoptr pop
      rhs = convert_to_int inttoptr pop
      push ptrtoint convert_to_str write true, "sub i64 #{lhs}, #{rhs}"

    when 'mul'
      lhs = convert_to_int inttoptr pop
      rhs = convert_to_int inttoptr pop
      push ptrtoint convert_to_str write true, "mul i64 #{lhs}, #{rhs}"
    when 'rep' then raise "todo"

    when 'div'
      lhs = convert_to_int inttoptr pop
      rhs = convert_to_int inttoptr pop
      push ptrtoint convert_to_str write true, "div i64 #{lhs}, #{rhs}"

    when 'mod'
      lhs = convert_to_int inttoptr pop
      rhs = convert_to_int inttoptr pop
      push ptrtoint convert_to_str write true, "srem i64 #{lhs}, #{rhs}"

    when 'eql'
      lhs = inttoptr pop
      rhs = inttoptr pop
      push ptrtoint write true, "call i32 @strcmp(i8* #{lhs}, i8* #{rhs})"
    when 'neq' then raise "todo"
    when 'lth' then raise "todo"
    when 'gth' then raise "todo"
    when 'leq' then raise "todo"
    when 'geq' then raise "todo"

    when 'print'
      value = inttoptr pop
      write true, "call i32 @puts(i8* #{value})"
    else
      raise "unrecognized token '#{kind}'"
    end
  end
end

# $DEBUG=1
input = $*.shift or abort "missing input file"
output = $*.shift || 'lance.out'

c = Compiler.new Parser.new File.read input
IO.pipe do |r,w|
  w.write c.tap(&:compile)
  puts c if $DEBUG
  w.close
  system 'clang', '-o', output, '-xir', '-', in: r
end


