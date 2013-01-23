child_process = require 'child_process'

segmenter = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'])

parser = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -jar BerkeleyParser-1.7.jar -chinese -gr chn_sm5.gr'])


segmenterResponsesNeeded = {}

segmenter.stdout.on('data', (data) ->
  result = data.toString().trim()
  query = result.split(' ').join('').trim()
  segmenterResponsesNeeded[query](data)
  delete segmenterResponsesNeeded[query]
  console.log('segstdout: ' + data)
)

segmenter.stderr.on('data', (data) ->
  console.log('segstderr: ' + data)
)

parserResponsesNeeded = {}

parser.stdout.on('data', (data) ->
  result = data.toString().trim()
  query = terminals(result)
  parserResponsesNeeded[query](data)
  delete parserResponsesNeeded[query]
  console.log('parserstdout: ' + data)
)

parser.stderr.on('data', (data) ->
  console.log('parserstderr: ' + data)
)

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

express = require 'express'
app = express()

http = require 'http'
httpserver = http.createServer(app)
httpserver.listen(3555);

app.get('/', (req, res) ->
  res.end 'either segment or parse'
)

app.get('/segment', (req,res) ->
  sentence = req.query['sentence']
  if sentence?
    query = sentence.split(' ').join('').trim()
    segmenterResponsesNeeded[query] = (segmented) -> res.end(segmented)
    segmenter.stdin.write(query + '\n\n\n\n')
  else
    res.end 'need to provide sentence parameter'
)

app.get('/parse', (req, res) ->
  sentence = req.query['sentence']
  if sentence?
    query = sentence.split(' ').join('').trim()
    segmenterResponsesNeeded[query] = (segmented) ->
      parserResponsesNeeded[query] = (parsed) -> res.end(parsed)
      parser.stdin.write(segmented)
    segmenter.stdin.write(query + '\n\n\n\n')
  else
    res.end 'need to provide sentence parameter'
)

