child_process = require 'child_process'
restler = require 'restler'
querystring = require 'querystring'

portnum = 3555

getUrl = (url, params, callback) ->
  paramstring = querystring.stringify(params)
  if url.indexOf('/') == -1
    url = 'http://localhost:' + portnum + '/' + url
  if paramstring == ''
    realurl = url
  else
    realurl = url + '?' + paramstring
  restler.get(realurl).on('complete', (httpgetresponse) ->
    callback(httpgetresponse)
  )

parsers = {}
parsers['zh'] = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -jar BerkeleyParser-1.7.jar -tokenize -chinese -gr chn_sm5.gr'])
parsers['en'] = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -jar BerkeleyParser-1.7.jar -tokenize -gr eng_sm6.gr'])
parsers['fr'] = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -jar BerkeleyParser-1.7.jar -tokenize -gr fra_sm5.gr'])
parsers['de'] = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -jar BerkeleyParser-1.7.jar -tokenize -gr ger_sm5.gr'])

#segmenter = null
segmenter = child_process.spawn('/bin/sh', ['-c', 'stdbuf -oL cat | java -mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'])

segmenterResponsesNeeded = {}

if segmenter?
  segmenter.stdout.on('data', (data) ->
    result = data.toString().trim()
    query = result.split(' ').join('').trim()
    if segmenterResponsesNeeded[query]?
      segmenterResponsesNeeded[query](data)
      delete segmenterResponsesNeeded[query]
    console.log('segstdout: ' + data)
  )

  segmenter.stderr.on('data', (data) ->
    console.log('segstderr: ' + data)
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
  return output.join('').split(' ').join('').trim()

parserResponsesNeeded = {}

for lang,parser of parsers
  parserResponsesNeeded[lang] = {}
  do (lang, parser) ->
    parser.stdout.on('data', (data) ->
      result = data.toString().trim()
      query = terminals(result)
      console.log 'response: query:' + query
      console.log parserResponsesNeeded[lang]
      console.log parserResponsesNeeded[lang][query]
      if parserResponsesNeeded[lang][query]?
        parserResponsesNeeded[lang][query](data)
        delete parserResponsesNeeded[lang][query]
      console.log('parserstdout: ' + data)
    )
    parser.stderr.on('data', (data) ->
      console.log('parserstderr: ' + data)
    )

#console.log (terminals ' ( (NP (NN cat)) )') + 'end'

express = require 'express'
app = express()

http = require 'http'
httpserver = http.createServer(app)

httpserver.listen(portnum);

app.get('/', (req, res) ->
  res.end 'either segment or parse'
)

app.get('/segment', (req,res) ->
  sentence = req.query['sentence']
  if sentence?
    query = sentence.split(' ').join('').trim()
    segmenterResponsesNeeded[query] = (segmented) ->
      if segmented?
        res.end(segmented)
    segmenter.stdin.write(query + '\n\n\n\n')
  else
    res.end 'need to provide sentence parameter'
)

app.get '/parseNoSegment', (req, res) ->
  sentence = req.query.sentence
  if not sentence?
    res.end 'need to provide sentence parameter'
    return
  lang = req.query.lang ? 'en'
  query = sentence.split(' ').join('').trim()
  console.log lang
  console.log query
  parserResponsesNeeded[lang][query] = (parsed) ->
    if parsed?
      res.end(parsed)
  parsers[lang].stdin.write(sentence + '\n')

app.get '/parse', (req, res) ->
  sentence = req.query.sentence
  if not sentence?
    res.end 'need to provide sentence parameter'
    return
  lang = req.query.lang ? 'en'
  if lang != 'zh'
    if not parsers[lang]?
      lang = 'zh'
    getUrl 'parseNoSegment', {'lang': lang, 'sentence': sentence}, (parsed) ->
      res.end parsed
    return
  else
    console.log 'sentence is:' + sentence
    await
      getUrl 'segment', {'lang': lang, 'sentence': sentence}, defer(segmented)
    console.log 'newly segmented sentence:' + segmented
    await
      getUrl 'parseNoSegment', {'lang': lang, 'sentence': segmented}, defer(parsed)
    console.log 'parsed output:' + parsed
    if parsed?
      res.end parsed
    return

