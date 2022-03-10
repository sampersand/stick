def next_token
  case $tokens.shift or return
  when /\A\d+\b/ then $1.to_i
  end
end

input = 'begin\n/a 1 = a 2 + P'
