
def master = '00:38:05 up 1 day, 22:47,  load average: 0.51, 0.29, 0.16'
def ubuntus1 = '20:38:06 up 55 days,  1:27,  1 user,  load average: 2.00, 2.00, 2.00'
def ubuntus2 = '20:38:10 up 55 days,  1:27,  0 users,  load average: 2.13, 2.06, 2.01'
def ubuntus3 = '20:38:11 up 1 day, 22:47,  1 user,  load average: 0.55, 0.31, 0.17'
def reg = ~/^\s*(\S{8})\s+up\s+([^u]+),\s+(\d+){0,1}(?:\susers{0,1},\s+){0,1}load\s+average:\s(\S+),\s+(\S+),\s+(\S+)/

def json = [ master : [ time : '00:38:05',
                         uptime : '1 day, 22:47', 
                         userCount : null, 
                         load : [ '01min average' : 0.51, '05min average' : 0.29, '45min average' : 0.16 ]
                         ],
              'ubuntu-s1' : [ time : '20:38:06',
                              uptime : '55 days,  1:27', 
                              userCount : 1, 
                              load : [ '01min average' : 2.00, '05min average' : 2.00, '45min average' : 2.00 ]
                             ],
               'ubuntu-s2' : [ time : '20:38:10',  
                               uptime : '55 days,  1:27',
                               userCount : 0, 
                               load : [ '01min average' : 2.13, '05min average' : 2.06, '45min average' : 2.01 ]
                              ], 
               'ubuntu-s3' : [ time : '20:38:11',  
                               uptime : '1 day, 22:47', 
                               userCount : 1, 
                               load : [ '01min average' : 0.55, '05min average' : 0.31, '45min average' : 0.17 ]
                              ]
            ]
            
def toJSON(obj) {
   def json = '' 
   if (obj instanceof Map) {
      json += '{'
      obj.each { k,v ->  json += String.format('"%s":%s,', k, toJSON(v)) }
      return json.substring(0,json.length()-1) + '}'
   }
   if (obj instanceof ArrayList) {
      json += '['
      obj.each { it -> json += toJSON(it)+ ',' }
      return json.substring(0,json.length()-1) + ']'
   }
   if (obj instanceof String) {
      return '"'+obj+'"'
   }
   return obj
}
//println toJSON(json)
(master =~ reg)[0].each{
  println it
}
''