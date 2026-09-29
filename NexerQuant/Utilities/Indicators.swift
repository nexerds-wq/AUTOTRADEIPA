import Foundation

enum Indicators {
 static func sma(_ x:[Double], _ n:Int)->Double? { guard x.count >= n else{return nil}; return x.suffix(n).reduce(0,+)/Double(n) }
 static func emaSeries(_ x:[Double], _ n:Int)->[Double] { guard !x.isEmpty else{return []}; let k=2.0/Double(n+1); var out=[x[0]]; for v in x.dropFirst(){out.append(v*k + out.last!*(1-k))}; return out }
 static func ema(_ x:[Double], _ n:Int)->Double? { guard x.count >= n else{return nil}; return emaSeries(x,n).last }
 static func rsi(_ x:[Double], _ n:Int=14)->Double? { guard x.count > n else{return nil}; let d=zip(x.dropFirst(),x).map(-); let s=Array(d.suffix(n)); let g=s.filter{$0>0}.reduce(0,+)/Double(n); let l=abs(s.filter{$0<0}.reduce(0,+))/Double(n); return l == 0 ? 100 : 100-(100/(1+g/l)) }
 static func macd(_ x:[Double])->(Double,Double,Double)? { guard x.count>=35 else{return nil}; let a=emaSeries(x,12), b=emaSeries(x,26); let start=max(0,a.count-b.count); let line=zip(a.dropFirst(start),b).map(-); guard let m=line.last, let sig=ema(line,9) else{return nil}; return (m,sig,m-sig) }
}
