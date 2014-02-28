#segmenter = require('child_process').spawn('./segmenter.sh')
#segmenter = require('child_process').spawn('java', '-mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'.split(' '))

pty = require 'pty.js'

segmenter = pty.spawn('/bin/sh', ['-c', 'java -mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'], {})

segmenter.on('data', (data) ->
  console.log('data: ' + data)
  if data.indexOf('done') == 0
    console.log 'have Done'
    segmenter.write('你好吗\r')
)

segmenter.write('你好吗\r')
#segmenter.stdin.
#console.log(segmenter.stdin)
#segmenter.stdin.end()

