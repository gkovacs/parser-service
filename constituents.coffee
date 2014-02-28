###
parse = '''
(
  (S
    (NP
      (DT the)
      (NN cat)
    )
    (VP
      (VBD ate)
    )
  )
)'''
###

refparse = '''
( (CP (IP (NP (PN 你们)) (VP (VV 记得) (NP (CP (IP (VP (NP (NT 昨天)) (VP (VV 做)))) (DEC 的)) (NP (NN 事))))) (SP 吗)) )
'''

#parse = '''
#( (ROOT (SENT (NP (N Hilda) (N Conkling)) (VPpart (V née) (NP (D le) (A 8) (N octobre) (N 1910)) (PP (P à) (NP (N Catskill-on-Hudson) (N New) (N York))) (C et) (AP (A morte)) (NP (D le) (A 26) (N juin) (N 1986))) (PP (P à) (NP (N Northampton) (N (Massachusetts) (N State)))) (VN (V est)) (NP (D un) (N poète) (N américain.)))) )
#'''

terminals = (s, lang) ->
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
  if lang == 'zh'
    return output.join('')
  return output.join(' ')

#terminals = (s) ->
#  return getChildren(s)

getChildren = (s) ->
  curchild = []
  children = []
  depth = 0
  for c in s
    if c == '('
      depth += 1
    if depth >= 2
      curchild.push c
    if c == ')'
      depth -= 1
      if depth == 1
        children.push curchild.join('')
        curchild = []
  return children

getParseConstituents = (parse, lang) ->
  output = {}
  agenda = [parse]
  while agenda.length > 0
    current = agenda.pop(0)
    for child in getChildren(current)
      agenda.push child
      curt = terminals(current, lang)
      childt = terminals(child, lang)
      if curt != childt
        if not output[curt]?
          output[curt] = []
        output[curt].push childt
  return output

getConstituents = (parse, lang) ->
  return {} # todo implement, return [start,end] -> list of [start, end]

parseToHierarchy = (parse, lang) ->
  output = []
  for children in getChildren(parse)
    output.push parseToHierarchy(children, lang)
  if output.length == 1
    return output[0]
  if output.length == 0
    return terminals(parse, lang)
  return output

#console.log terminals parse
#console.log getParseConstituents(parse, 'zh')

hierarchyToTerminals = (hierarchy, lang) ->
  if typeof hierarchy == typeof []
    children = (hierarchyToTerminals(x, lang) for x in hierarchy)
    if lang == 'zh'
      return children.join('')
    else
      return children.join(' ')
  else
    return hierarchy

subHierarchies = (hierarchy) ->
  output = []
  agenda = [hierarchy]
  while agenda.length > 0
    current = agenda.pop(0)
    output.push current
    #console.log hierarchyToTerminals(current)
    if typeof current == typeof []
      for x in current
        agenda.push x
  return output

#console.log parseToHierarchy(refparse, 'zh')
console.log parseToHierarchy(refparse, 'zh')

