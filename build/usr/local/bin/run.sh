#!/bin/bash
lib.functions "$(crf.LIB)" 'unset'
/sbin/tini -s -v -- /usr/local/bin/jenkins.sh
