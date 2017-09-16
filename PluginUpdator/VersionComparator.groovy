
def compare(a,b) {
  def VALID_TOKENS = /._/
  a = a.tokenize(VALID_TOKENS)
  b = b.tokenize(VALID_TOKENS)
  
  for (i in 0..<Math.max(a.size(), b.size())) {
    if (i == a.size()) {
      return b[i].isInteger() ? -1 : 1
    } else if (i == b.size()) {
      return a[i].isInteger() ? 1 : -1
    }
    
    if (a[i].isInteger() && b[i].isInteger()) {
      int c = (a[i] as int) <=> (b[i] as int)
      if (c != 0) {
        return c
      }
    } else if (a[i].isInteger()) {
      return 1
    } else if (b[i].isInteger()) {
      return -1
    } else {
      int c = a[i] <=> b[i]
      if (c != 0) {
        return c
      }
    }
  }
  
  return 0
}