import Foundation
import SwiftUI

@MainActor final class TradingStore: ObservableObject {
    @Published var settings = StrategySettings()
    @Published var cash = 10000.0
    @Published var positions:[Position] = []
    @Published var trades:[Trade] = []
    @Published var scans:[ScanResult] = []
    @Published var isScanning = false
    @Published var scanStatus = "Ready"
    let data = MarketDataService()

    let universe:[Asset] = [
        .init(symbol:"SPY",name:"S&P 500 ETF",assetClass:.etfs),.init(symbol:"QQQ",name:"Nasdaq 100 ETF",assetClass:.etfs),.init(symbol:"IWM",name:"Russell 2000 ETF",assetClass:.etfs),.init(symbol:"DIA",name:"Dow Jones ETF",assetClass:.etfs),.init(symbol:"XLK",name:"Technology ETF",assetClass:.etfs),.init(symbol:"XLF",name:"Financial ETF",assetClass:.etfs),.init(symbol:"XLE",name:"Energy ETF",assetClass:.etfs),.init(symbol:"XLV",name:"Health Care ETF",assetClass:.etfs),.init(symbol:"XLI",name:"Industrial ETF",assetClass:.etfs),.init(symbol:"SMH",name:"Semiconductor ETF",assetClass:.etfs),.init(symbol:"VTI",name:"Total US Market ETF",assetClass:.etfs),.init(symbol:"TLT",name:"Treasury ETF",assetClass:.etfs),.init(symbol:"GLD",name:"Gold ETF",assetClass:.etfs),
        .init(symbol:"AAPL",name:"Apple",assetClass:.stocks),.init(symbol:"MSFT",name:"Microsoft",assetClass:.stocks),.init(symbol:"NVDA",name:"NVIDIA",assetClass:.stocks),.init(symbol:"AMZN",name:"Amazon",assetClass:.stocks),.init(symbol:"GOOGL",name:"Alphabet",assetClass:.stocks),.init(symbol:"META",name:"Meta",assetClass:.stocks),.init(symbol:"AVGO",name:"Broadcom",assetClass:.stocks),.init(symbol:"AMD",name:"AMD",assetClass:.stocks),.init(symbol:"NFLX",name:"Netflix",assetClass:.stocks),.init(symbol:"ORCL",name:"Oracle",assetClass:.stocks),.init(symbol:"CRM",name:"Salesforce",assetClass:.stocks),.init(symbol:"COST",name:"Costco",assetClass:.stocks),.init(symbol:"JPM",name:"JPMorgan",assetClass:.stocks),.init(symbol:"V",name:"Visa",assetClass:.stocks),.init(symbol:"MA",name:"Mastercard",assetClass:.stocks),.init(symbol:"WMT",name:"Walmart",assetClass:.stocks),.init(symbol:"HD",name:"Home Depot",assetClass:.stocks),.init(symbol:"LLY",name:"Eli Lilly",assetClass:.stocks),.init(symbol:"XOM",name:"Exxon Mobil",assetClass:.stocks),.init(symbol:"CAT",name:"Caterpillar",assetClass:.stocks),.init(symbol:"IBM",name:"IBM",assetClass:.stocks),.init(symbol:"CSCO",name:"Cisco",assetClass:.stocks),.init(symbol:"QCOM",name:"Qualcomm",assetClass:.stocks)
    ]

    var equity:Double { cash + positions.reduce(0){$0+$1.value} }

    func scan() async {
        guard !isScanning else { return }
        isScanning=true; scanStatus="Starting scan…"
        defer { isScanning=false }
        var output:[ScanResult]=[]
        for (index,asset) in universe.enumerated() {
            if Task.isCancelled { scanStatus="Scan cancelled"; return }
            scanStatus="Scanning \(index+1) of \(universe.count): \(asset.symbol)"
            do {
                let market=try await data.series(symbol:asset.symbol)
                if let signal=makeSignal(asset:asset,market:market) { output.append(signal) }
            } catch { continue }
        }
        scans=output.sorted{$0.score == $1.score ? $0.momentum12>$1.momentum12 : $0.score>$1.score}
        guard !scans.isEmpty else { scanStatus="No market data returned. Try again."; return }
        scanStatus="Finished • \(scans.count) markets"
        markPositions()
        if settings.autoEnabled { autoTrade() }
    }

    private func makeSignal(asset:Asset,market:MarketSeries)->ScanResult? {
        let c=market.closes.filter{$0.isFinite && $0>0}
        guard c.count>=252 else{return nil}
        let p=c[c.count-1], base12=c[c.count-252], base6=c[c.count-126]
        guard p>0,base12>0,base6>0 else{return nil}
        let ma200=Array(c.suffix(200)).reduce(0,+)/200.0
        let mom12=(p/base12-1)*100, mom6=(p/base6-1)*100
        guard mom12.isFinite,mom6.isFinite,ma200.isFinite else{return nil}
        let above=p>ma200
        let prior=Array(c.dropLast().suffix(63)); let high=prior.max() ?? p; let breakout=p>=high
        let recent=Array(c.suffix(61)); var rs:[Double]=[]
        if recent.count>1 { for i in 1..<recent.count { let prev=recent[i-1]; if prev>0 { let r=recent[i]/prev-1; if r.isFinite { rs.append(r) } } } }
        let mean=rs.isEmpty ? 0 : rs.reduce(0,+)/Double(rs.count)
        let variance=rs.isEmpty ? 0 : rs.reduce(0){$0+($1-mean)*($1-mean)}/Double(rs.count)
        let vol=sqrt(max(0,variance))*sqrt(252.0)*100
        guard vol.isFinite else{return nil}
        var score=0; if above{score+=30};if mom12>0{score+=25};if mom6>0{score+=20};if mom6>mom12/2{score+=10};if breakout{score+=10};if vol<45{score+=5}
        let why="12M \(String(format:"%.1f",mom12))% • 6M \(String(format:"%.1f",mom6))% • \(above ? "above":"below") 200D • vol \(String(format:"%.1f",vol))%"
        return .init(asset:asset,price:p,score:score,momentum12:mom12,momentum6:mom6,above200:above,volatility:vol,breakout:breakout,reason:why)
    }

    private func markPositions(){for i in positions.indices{if let q=scans.first(where:{$0.asset.symbol==positions[i].symbol}){positions[i].current=q.price;positions[i].peak=max(positions[i].peak,q.price)}}}

    func autoTrade(){
        let eligible=scans.filter{$0.above200 && $0.momentum12>0 && $0.momentum6>0 && $0.score>=65};guard !eligible.isEmpty else{return}
        let count=min(8,max(3,eligible.count));let targets=Set(eligible.prefix(count).map{$0.asset.symbol})
        for p in positions.reversed(){guard let q=scans.first(where:{$0.asset.symbol==p.symbol}) else{continue};if !q.above200 || q.momentum6<=0 || q.price<=max(p.stop,p.peak*0.90) || !targets.contains(p.symbol){sell(symbol:p.symbol,price:q.price,reason:"Trend/rank exit")}}
        let value=max(equity,1),allocation=min(0.18,0.90/Double(count))
        for x in eligible.prefix(count){guard !positions.contains(where:{$0.symbol==x.asset.symbol}),x.price>0 else{continue};let spend=min(cash,value*allocation);guard spend>=25 else{continue};let qty=spend/x.price;cash-=spend;positions.append(.init(id:UUID(),symbol:x.asset.symbol,quantity:qty,entry:x.price,current:x.price,stop:x.price*0.92,peak:x.price,opened:Date()));trades.insert(.init(id:UUID(),symbol:x.asset.symbol,side:"BUY",quantity:qty,price:x.price,date:Date(),reason:"Ranked trend + dual momentum",pnl:nil),at:0)}
    }
    private func sell(symbol:String,price:Double,reason:String){guard let i=positions.firstIndex(where:{$0.symbol==symbol}) else{return};let p=positions[i];cash+=p.quantity*price;positions.remove(at:i);trades.insert(.init(id:UUID(),symbol:symbol,side:"SELL",quantity:p.quantity,price:price,date:Date(),reason:reason,pnl:(price-p.entry)*p.quantity),at:0)}
    func reset(){cash=settings.startingCash;positions=[];trades=[];scans=[];scanStatus="Ready"}
}
