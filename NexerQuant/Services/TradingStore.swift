import Foundation
import SwiftUI

@MainActor final class TradingStore: ObservableObject {
 @Published var settings=StrategySettings(); @Published var cash=10000.0; @Published var positions:[Position]=[]; @Published var trades:[Trade]=[]; @Published var scans:[ScanResult]=[]; @Published var isScanning=false; @Published var apiKey=""
 let data=MarketDataService()
 let universe:[Asset] = [
  .init(symbol:"SPY",name:"S&P 500 ETF",assetClass:.etfs),.init(symbol:"QQQ",name:"Nasdaq 100 ETF",assetClass:.etfs),.init(symbol:"IWM",name:"Russell 2000 ETF",assetClass:.etfs),
  .init(symbol:"AAPL",name:"Apple",assetClass:.stocks),.init(symbol:"MSFT",name:"Microsoft",assetClass:.stocks),.init(symbol:"NVDA",name:"NVIDIA",assetClass:.stocks),.init(symbol:"AMZN",name:"Amazon",assetClass:.stocks),.init(symbol:"GOOGL",name:"Alphabet",assetClass:.stocks),.init(symbol:"META",name:"Meta",assetClass:.stocks),.init(symbol:"TSLA",name:"Tesla",assetClass:.stocks),
  .init(symbol:"BTC/USD",name:"Bitcoin",assetClass:.crypto),.init(symbol:"ETH/USD",name:"Ethereum",assetClass:.crypto),.init(symbol:"SOL/USD",name:"Solana",assetClass:.crypto),
  .init(symbol:"EUR/USD",name:"Euro / Dollar",assetClass:.forex),.init(symbol:"GBP/USD",name:"Pound / Dollar",assetClass:.forex),.init(symbol:"USD/JPY",name:"Dollar / Yen",assetClass:.forex)
 ]
 var equity:Double { cash + positions.reduce(0){$0+$1.value} }
 func scan() async { isScanning=true; defer{isScanning=false}; var r:[ScanResult]=[]
  for a in universe { if let c=try? await data.candles(symbol:a.symbol,apiKey:apiKey), c.count>200, let e200=Indicators.ema(c,settings.slowMA), let e50=Indicators.ema(c,settings.fastMA), let rs=Indicators.rsi(c) { let p=c.last!; let look=min(c.count-1,252); let mom=(p/c[c.count-1-look]-1)*100; let mac=Indicators.macd(c); var score=0; if mom>0{score+=30}; if p>e200{score+=25}; if e50>e200{score+=15}; if rs>=50 && rs<=70{score+=10}; if let m=mac, m.0>m.1{score+=10}; if mom>10{score+=10}; let why="Momentum \(String(format:"%.1f",mom))% • RSI \(String(format:"%.0f",rs)) • \(p>e200 ? "Above" : "Below") 200 EMA"; r.append(.init(asset:a,price:p,score:score,momentum:mom,above200:p>e200,rsi:rs,reason:why)) } }
  scans=r.sorted{$0.score>$1.score}; if settings.autoEnabled { autoTrade() }
 }
 func autoTrade(){ for s in scans where s.score >= settings.minimumScore && s.momentum > 0 && s.above200 { guard positions.count < settings.maxPositions, !positions.contains(where:{$0.symbol==s.asset.symbol}) else{continue}; let maxValue=equity*settings.maxPositionPct/100; let risk=equity*settings.riskPct/100; let stop=s.price*0.94; let qty=min(maxValue/s.price, risk/max(0.01,s.price-stop)); let cost=qty*s.price; guard qty>0,cost<=cash else{continue}; cash-=cost; positions.append(.init(id:UUID(),symbol:s.asset.symbol,quantity:qty,entry:s.price,current:s.price,stop:stop,opened:Date())); trades.insert(.init(id:UUID(),symbol:s.asset.symbol,side:"AUTO BUY",quantity:qty,price:s.price,date:Date(),reason:s.reason),at:0) } }
 func reset(){cash=settings.startingCash;positions=[];trades=[]}
}
