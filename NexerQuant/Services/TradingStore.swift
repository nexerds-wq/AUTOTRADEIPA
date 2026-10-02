import Foundation
import SwiftUI

@MainActor final class TradingStore: ObservableObject {
 @Published var settings=StrategySettings(); @Published var cash=10000.0; @Published var positions:[Position]=[]; @Published var trades:[Trade]=[]; @Published var scans:[ScanResult]=[]; @Published var isScanning=false; @Published var apiKey=""
 let data=MarketDataService()
 let universe:[Asset] = [
  .init(symbol:"SPY",name:"S&P 500 ETF",assetClass:.etfs),.init(symbol:"QQQ",name:"Nasdaq 100 ETF",assetClass:.etfs),.init(symbol:"IWM",name:"Russell 2000 ETF",assetClass:.etfs),
  .init(symbol:"XLK",name:"Technology Select Sector ETF",assetClass:.etfs),.init(symbol:"SMH",name:"Semiconductor ETF",assetClass:.etfs),.init(symbol:"DIA",name:"Dow Jones ETF",assetClass:.etfs),
  .init(symbol:"AAPL",name:"Apple",assetClass:.stocks),.init(symbol:"MSFT",name:"Microsoft",assetClass:.stocks),.init(symbol:"NVDA",name:"NVIDIA",assetClass:.stocks),.init(symbol:"AMD",name:"AMD",assetClass:.stocks),.init(symbol:"AMZN",name:"Amazon",assetClass:.stocks),.init(symbol:"GOOGL",name:"Alphabet",assetClass:.stocks),.init(symbol:"META",name:"Meta",assetClass:.stocks),.init(symbol:"TSLA",name:"Tesla",assetClass:.stocks),.init(symbol:"AVGO",name:"Broadcom",assetClass:.stocks),.init(symbol:"NFLX",name:"Netflix",assetClass:.stocks),.init(symbol:"ORCL",name:"Oracle",assetClass:.stocks),.init(symbol:"CRM",name:"Salesforce",assetClass:.stocks),
  .init(symbol:"BTC/USD",name:"Bitcoin",assetClass:.crypto),.init(symbol:"ETH/USD",name:"Ethereum",assetClass:.crypto),.init(symbol:"SOL/USD",name:"Solana",assetClass:.crypto),
  .init(symbol:"EUR/USD",name:"Euro / Dollar",assetClass:.forex),.init(symbol:"GBP/USD",name:"Pound / Dollar",assetClass:.forex),.init(symbol:"USD/JPY",name:"Dollar / Yen",assetClass:.forex),.init(symbol:"USD/CAD",name:"Dollar / Canadian Dollar",assetClass:.forex)
 ]
 var equity:Double { cash + positions.reduce(0){$0+$1.value} }
 func scan() async { isScanning=true; defer{isScanning=false}; var r:[ScanResult]=[]
  for a in universe { if let c=try? await data.candles(symbol:a.symbol,apiKey:apiKey), c.count>200, let e200=Indicators.ema(c,settings.slowMA), let e50=Indicators.ema(c,settings.fastMA), let rs=Indicators.rsi(c) { let p=c.last!; let look=min(c.count-1,252); let mom=(p/c[c.count-1-look]-1)*100; let mac=Indicators.macd(c); var score=0; if mom>0{score+=30}; if p>e200{score+=25}; if e50>e200{score+=15}; if rs>=50 && rs<=70{score+=10}; if let m=mac, m.0>m.1{score+=10}; if mom>10{score+=10}; let why="Momentum \(String(format:"%.1f",mom))% • RSI \(String(format:"%.0f",rs)) • \(p>e200 ? "Above" : "Below") 200 EMA"; r.append(.init(asset:a,price:p,score:score,momentum:mom,above200:p>e200,rsi:rs,reason:why)) } }
  scans=r.sorted{$0.score>$1.score}; if settings.autoEnabled { autoTrade() }
 }

 // Adaptive paper-trading decision engine. The strategy can vary position size based on
 // setup quality, but hard portfolio/risk limits remain outside its control.
 func autoTrade(){
  let candidates = scans.filter { $0.score >= settings.minimumScore && $0.momentum > 0 && $0.above200 && $0.rsi < 75 }
  for s in candidates {
   guard positions.count < settings.maxPositions, !positions.contains(where:{$0.symbol==s.asset.symbol}), cash > 0 else { continue }

   // Convert the strategy evidence into a confidence value from 0...1.
   let scoreConfidence = min(1.0, max(0.0, Double(s.score - settings.minimumScore + 20) / 40.0))
   let momentumConfidence = min(1.0, max(0.0, s.momentum / 30.0))
   let rsiConfidence = max(0.0, 1.0 - abs(s.rsi - 60.0) / 20.0)
   let confidence = min(1.0, max(0.0, scoreConfidence*0.55 + momentumConfidence*0.30 + rsiConfidence*0.15))

   // Better setups can receive more capital. Weak qualifying setups stay small.
   // maxPositionPct is still an absolute safety ceiling.
   let adaptivePct = settings.minAdaptivePositionPct + (settings.maxPositionPct-settings.minAdaptivePositionPct)*confidence
   let maxValue = min(equity*settings.maxPositionPct/100, equity*adaptivePct/100)

   // Stop distance adapts slightly to setup quality while never removing the stop.
   let stopPct = 0.045 + (1.0-confidence)*0.025
   let stop = s.price*(1.0-stopPct)
   let riskBudget = equity*settings.riskPct/100
   let qtyByRisk = riskBudget/max(0.01,s.price-stop)
   let qtyByCapital = maxValue/s.price
   let qty = min(qtyByRisk,qtyByCapital)
   let cost = qty*s.price
   guard qty>0, cost<=cash else { continue }

   cash-=cost
   positions.append(.init(id:UUID(),symbol:s.asset.symbol,quantity:qty,entry:s.price,current:s.price,stop:stop,opened:Date()))
   let decision="Adaptive confidence \(Int(confidence*100))% • allocation \(String(format:"%.1f",adaptivePct))% • \(s.reason)"
   trades.insert(.init(id:UUID(),symbol:s.asset.symbol,side:"ADAPTIVE BUY",quantity:qty,price:s.price,date:Date(),reason:decision),at:0)
  }
 }
 func reset(){cash=settings.startingCash;positions=[];trades=[]}
}
