child_process = require 'child_process'
restler = require 'restler'
querystring = require 'querystring'
fs = require 'fs'

portnum = 3555

getUrl = (url, params, callback) ->
  paramstring = querystring.stringify(params)
  if url.indexOf('/') == -1
    url = 'http://localhost:' + portnum + '/' + url
  if paramstring == ''
    realurl = url
  else
    realurl = url + '?' + paramstring
  restler.get(realurl).on 'complete', (httpgetresponse) ->
    callback(httpgetresponse)

stdbuf = 'stdbuf -oL cat | '
# on osx, need to install stdbuf via https://github.com/paulp/homebrew-extras first

parsers = {}

parsers['zh'] = child_process.spawn('/bin/sh', ['-c', stdbuf + 'java -mx2g -Dfile.encoding=UTF-8 -jar BerkeleyParser-1.7.jar -chinese -gr chn_sm5.gr'])
parsers['en'] = child_process.spawn('/bin/sh', ['-c', stdbuf + 'java -mx2g -Dfile.encoding=UTF-8 -jar BerkeleyParser-1.7.jar -gr eng_sm6.gr'])
#parsers['fr'] = child_process.spawn('/bin/sh', ['-c', stdbuf + 'java -mx2g -Dfile.encoding=UTF-8 -jar BerkeleyParser-1.7.jar -gr fra_sm5.gr'])
#parsers['de'] = child_process.spawn('/bin/sh', ['-c', stdbuf + 'java -mx2g -Dfile.encoding=UTF-8 -jar BerkeleyParser-1.7.jar -gr ger_sm5.gr'])
segmenter = child_process.spawn('/bin/sh', ['-c', stdbuf + 'java -mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'])

segmenterResponsesNeeded = {}

if segmenter?
  segmenter.stdout.on 'data', (data) ->
    result = data.toString().trim()
    console.log('segstdout: ' + result)
    query = result.split(' ').join('').trim()
    if segmenterResponsesNeeded[query]?
      segmenterResponsesNeeded[query](result)
      delete segmenterResponsesNeeded[query]

  segmenter.stderr.on 'data', (data) ->
    console.log('segstderr: ' + data)

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

do ->
  for let lang,parser of parsers
    parserResponsesNeeded[lang] = []
    parser.stdout.on 'data', (data) ->
      result = data.toString(encoding='utf8').trim()
      #query = terminals(result)
      #console.log 'response: query:' + query
      console.log parserResponsesNeeded[lang]
      #console.log parserResponsesNeeded[lang][query]
      #if parserResponsesNeeded[lang][query]?
      #  parserResponsesNeeded[lang][query](data)
      #  delete parserResponsesNeeded[lang][query]
      if parserResponsesNeeded[lang].length > 0
        curCallback = parserResponsesNeeded[lang].shift()
        curCallback(result)
      console.log('parserstdout: ' + result)
    parser.stderr.on 'data', (data) ->
      console.log('parserstderr: ' + data)

#console.log (terminals ' ( (NP (NN cat)) )') + 'end'

express = require 'express'
app = express()

http = require 'http'
httpserver = http.createServer(app)

httpserver.listen(portnum);

app.get '/', (req, res) ->
  res.end 'either segment or parse'

segment = (params, callback) ->
  {sentence} = params
  if sentence?
    console.log 'segment sentence: ' + sentence
    query = sentence.split(' ').join('').trim()
    segmenterResponsesNeeded[query] = (segmented) ->
      if segmented?
        console.log 'got segmented: ' + segmented
        callback(segmented)
    segmenter.stdin.write(query + '\n\n\n\n', encoding='utf8')
  else
    callback 'need to provide sentence parameter'

app.get '/segment', (req, res) ->
  segment req.query, (segmented) ->
    res.end segmented

parseNoSegment = (params, callback) ->
  {sentence, lang} = params
  if not sentence?
    callback 'need to provide sentence parameter'
    return
  lang = lang ? 'en'
  query = sentence.split(' ').join('').trim()
  console.log lang
  console.log query
  #parserResponsesNeeded[lang][query] = (parsed) ->
  #  if parsed?
  #    res.end(parsed)
  parserResponsesNeeded[lang].push (parsed) ->
    if parsed?
      callback(parsed)
  parsers[lang].stdin.write(sentence + '\n', encoding='utf8')

app.get '/parseNoSegment', (req, res) ->
  parseNoSegment req.query, (parsed) ->
    res.end parsed

app.get '/parse', (req, res) ->
  {sentence} = req.query
  if not sentence?
    res.end 'need to provide sentence parameter'
    return
  lang = req.query.lang ? 'en'
  if lang != 'zh'
    if not parsers[lang]?
      lang = 'zh'
    parseNoSegment {'lang': lang, 'sentence': sentence}, (parsed) ->
      res.end parsed
    return
  else
    console.log 'sentence is:' + sentence
    segment {'lang': lang, 'sentence': sentence}, (segmented) ->
      console.log 'newly segmented sentence:' + segmented
      parseNoSegment {'lang': lang, 'sentence': segmented}, (parsed) ->
        console.log 'parsed output:' + parsed
        if parsed?
          res.end parsed
        return
