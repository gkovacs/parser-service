#!/usr/bin/env python
# -*- coding: utf-8 -*-


import subprocess

args = ['stdbuf', '--output=L'] + ' java -mx2g -cp u/nlp/distrib/stanford-segmenter-2012-11-11/seg.jar edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict u/nlp/distrib/stanford-segmenter-2012-11-11/data -sighanPostProcessing true -loadClassifier u/nlp/distrib/stanford-segmenter-2012-11-11/data/ctb.gz -serDictionary u/nlp/distrib/stanford-segmenter-2012-11-11/data/dict-chris6.ser.gz -testFile /dev/stdin'.split()

#args = ['sleep 10; cat -u | stdbuf -oL cut -d aq aq -f1']

process = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=1)

print '===popen completed==='

#process.stdin.write('你好吗')

#while True:
#  (stdout,stderr) = process.communicate('你好吗')
#  print stdout
#  print stderr

while True:
  process.stdin.write('你好吗\n')
  process.stdin.flush()
  nline = process.stdout.readline()
  if nline.strip() != '':
    print nline

