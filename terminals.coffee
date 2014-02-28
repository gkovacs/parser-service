terminals = (s) ->
  output = []
  current_terminal = []
  for c in s
    if c == '('
      last_paren_type = '('
      current_terminal = []
    else if c == ')'
      if last_paren_type == '('
        if current_terminal.length > 0
          to_print = current_terminal.join('')
          [tag,terminal] = to_print.split(' ')
          output.push terminal
      last_paren_type = ')'
      current_terminal = []
    else
      current_terminal.push(c)
  return output.join('')

console.log terminals '( (IP (NP (PN 你们)) (VP (VV 好像) (VP (VV 不想) (IP (VP (VV 学习)))))) )'
