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
        .init(symbol:"SPY",name:"S&P 500 ETF",assetClass:.etfs), .init(symbol:"QQQ",name:"Nasdaq 100 ETF",assetClass:.etfs), .init(symbol:"IWM",name:"Russell 2000 ETF",assetClass:.etfs), .init(symbol:"DIA",name:"Dow Jones ETF",assetClass:.etfs),
        .init(symbol:"XLK",name:"Technology ETF",assetClass:.etfs), .init(symbol:"XLF",name:"Financial ETF",assetClass:.etfs), .init(symbol:"XLE",name:"Energy ETF",assetClass:.etfs), .init(symbol:"XLV",name:"Health Care ETF",assetClass:.etfs),
        .init(symbol:"XLI",name:"Industrial ETF",assetClass:.etfs), .init(symbol:"XLY",name:"Consumer Discretionary ETF",assetClass:.etfs), .init(symbol:"XLP",name:"Consumer Staples ETF",assetClass:.etfs), .init(symbol:"XLU",name:"Utilities ETF",assetClass:.etfs),
        .init(symbol:"SMH",name:"Semiconductor ETF",assetClass:.etfs), .init(symbol:"VTI",name:"Total US Market ETF",assetClass:.etfs), .init(symbol:"VEA",name:"Developed Markets ETF",assetClass:.etfs), .init(symbol:"VWO",name:"Emerging Markets ETF",assetClass:.etfs),
        .init(symbol:"TLT",name:"20+ Year Treasury ETF",assetClass:.etfs), .init(symbol:"GLD",name:"Gold ETF",assetClass:.etfs), .init(symbol:"AAPL",name:"Apple",assetClass:.stocks), .init(symbol:"MSFT",name:"Microsoft",assetClass:.stocks),
        .init(symbol:"NVDA",name:"NVIDIA",assetClass:.stocks), .init(symbol:"AMZN",name:"Amazon",assetClass:.stocks), .init(symbol:"GOOGL",name:"Alphabet",assetClass:.stocks), .init(symbol:"META",name:"Meta",assetClass:.stocks),
        .init(symbol:"AVGO",name:"Broadcom",assetClass:.stocks), .init(symbol:"AMD",name:"AMD",assetClass:.stocks), .init(symbol:"NFLX",name:"Netflix",assetClass:.stocks), .init(symbol:"ORCL",name:"Oracle",assetClass:.stocks),
        .init(symbol:"CRM",name:"Salesforce",assetClass:.stocks), .init(symbol:"COST",name:"Costco",assetClass:.stocks), .init(symbol:"JPM",name:"JPMorgan",assetClass:.stocks), .init(symbol:"V",name:"Visa",assetClass:.stocks),
        .init(symbol:"MA",name:"Mastercard",assetClass:.stocks), .init(symbol:"WMT",name:"Walmart",assetClass:.stocks), .init(symbol:"HD",name:"Home Depot",assetClass:.stocks), .init(symbol:"LLY",name:"Eli Lilly",assetClass:.stocks),
        .init(symbol:"UNH",name:"UnitedHealth",assetClass:.stocks), .init(symbol:"XOM",name:"Exxon Mobil",assetClass:.stocks), .init(symbol:"CAT",name:"Caterpillar",assetClass:.stocks), .init(symbol:"GE",name:"GE Aerospace",assetClass:.stocks),
        .init(symbol:"IBM",name:"IBM",assetClass:.stocks), .init(symbol:"CSCO",name:"Cisco",assetClass:.stocks), .init(symbol:"ADBE",name:"Adobe",assetClass:.stocks), .init(symbol:"INTC",name:"Intel",assetClass:.stocks), .init(symbol:"QCOM",name:"Qualcomm",assetClass:.stocks)
    ]

    var equity:Double { cash + positions.reduce(0) { $0 + $1.value } }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        scanStatus = "Downloading market data…"
        defer { isScanning = false }

        let assets = universe
        let service = data
        var results:[ScanResult] = []

        await withTaskGroup(of: ScanResult?.self) { group in
            for asset in assets {
                group.addTask {
                    do {
                        let m = try await service.series(symbol: asset.symbol)
                        return Self.makeSignal(asset: asset, market: m)
                    } catch {
                        return nil
                    }
                }
            }
            for await result in group {
                if let result { results.append(result) }
            }
        }

        guard !results.isEmpty else {
            scans = []
            scanStatus = "Market data unavailable. Try again shortly."
            return
        }

        scans = results.sorted { $0.score == $1.score ? $0.momentum12 > $1.momentum12 : $0.score > $1.score }
        scanStatus = "Analyzed \(scans.count) markets"
        markPositions()
        if settings.autoEnabled { autoTrade() }
    }

    nonisolated private static func makeSignal(asset:Asset, market:MarketSeries) -> ScanResult? {
        let c = market.closes.filter { $0.isFinite && $0 > 0 }
        guard c.count >= 252, let p = c.last, let ma200 = Indicators.sma(c,200), p.isFinite, ma200.isFinite else { return nil }
        let base12 = c[c.count-252]
        let base6 = c[c.count-126]
        guard base12 > 0, base6 > 0 else { return nil }
        let mom12 = (p/base12-1)*100
        let mom6 = (p/base6-1)*100
        let above200 = p > ma200
        let recentHigh = c.dropLast().suffix(63).max() ?? p
        let breakout = p >= recentHigh
        let recent = Array(c.suffix(61))
        guard recent.count > 2 else { return nil }
        var returns:[Double] = []
        for i in 1..<recent.count where recent[i-1] > 0 { returns.append(recent[i]/recent[i-1]-1) }
        let mean = returns.reduce(0,+)/Double(max(returns.count,1))
        let variance = returns.reduce(0){$0+pow($1-mean,2)}/Double(max(returns.count,1))
        let volatility = sqrt(max(variance,0))*sqrt(252)*100
        guard mom12.isFinite, mom6.isFinite, volatility.isFinite else { return nil }
        var score=0
        if above200 { score += 30 }; if mom12 > 0 { score += 25 }; if mom6 > 0 { score += 20 }
        if mom6 > mom12/2 { score += 10 }; if breakout { score += 10 }; if volatility < 45 { score += 5 }
        let reason="12M \(String(format:"%.1f",mom12))% • 6M \(String(format:"%.1f",mom6))% • \(above200 ? "above":"below") 200D • vol \(String(format:"%.1f",volatility))%"
        return .init(asset:asset,price:p,score:score,momentum12:mom12,momentum6:mom6,above200:above200,volatility:volatility,breakout:breakout,reason:reason)
    }

    private func markPositions() {
        for i in positions.indices {
            if let q=scans.first(where:{$0.asset.symbol==positions[i].symbol}) { positions[i].current=q.price; positions[i].peak=max(positions[i].peak,q.price) }
        }
    }

    func autoTrade() {
        let eligible=scans.filter{$0.above200 && $0.momentum12>0 && $0.momentum6>0 && $0.score>=65}
        guard !eligible.isEmpty else { return }
        let targetCount=min(8,max(3,eligible.count)); let targetSymbols=Set(eligible.prefix(targetCount).map{$0.asset.symbol})
        for p in positions.reversed() {
            guard let q=scans.first(where:{$0.asset.symbol==p.symbol}) else { continue }
            if !q.above200 || q.momentum6<=0 || q.price<=max(p.stop,p.peak*0.90) || !targetSymbols.contains(p.symbol) { sell(symbol:p.symbol,price:q.price,reason:"Trend/rank exit") }
        }
        let portfolioValue=max(equity,1); let allocation=min(0.18,0.90/Double(targetCount))
        for signal in eligible.prefix(targetCount) {
            guard !positions.contains(where:{$0.symbol==signal.asset.symbol}), signal.price>0 else { continue }
            let spend=min(cash,portfolioValue*allocation); guard spend>=25 else { continue }
            let qty=spend/signal.price; cash-=spend
            positions.append(.init(id:UUID(),symbol:signal.asset.symbol,quantity:qty,entry:signal.price,current:signal.price,stop:signal.price*0.92,peak:signal.price,opened:Date()))
            trades.insert(.init(id:UUID(),symbol:signal.asset.symbol,side:"BUY",quantity:qty,price:signal.price,date:Date(),reason:"Ranked trend + dual momentum",pnl:nil),at:0)
        }
    }

    private func sell(symbol:String,price:Double,reason:String) {
        guard let i=positions.firstIndex(where:{$0.symbol==symbol}) else { return }; let p=positions[i]
        cash += p.quantity*price; positions.remove(at:i)
        trades.insert(.init(id:UUID(),symbol:symbol,side:"SELL",quantity:p.quantity,price:price,date:Date(),reason:reason,pnl:(price-p.entry)*p.quantity),at:0)
    }

    func reset(){cash=settings.startingCash;positions=[];trades=[];scans=[];scanStatus="Ready"}
}
