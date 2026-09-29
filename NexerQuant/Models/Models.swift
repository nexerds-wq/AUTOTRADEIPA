import Foundation

enum AssetClass: String, Codable, CaseIterable, Identifiable { case stocks = "Stocks", etfs = "ETFs", crypto = "Crypto", forex = "Forex"; var id:String { rawValue } }
struct Asset: Identifiable, Codable, Hashable { let symbol:String; let name:String; let assetClass:AssetClass; var id:String { symbol } }
struct Position: Identifiable, Codable { let id:UUID; let symbol:String; var quantity:Double; var entry:Double; var current:Double; var stop:Double; let opened:Date; var value:Double { quantity*current }; var pnl:Double {(current-entry)*quantity} }
struct Trade: Identifiable, Codable { let id:UUID; let symbol:String; let side:String; let quantity:Double; let price:Double; let date:Date; let reason:String }
struct StrategySettings: Codable {
    var autoEnabled=false; var startingCash=10000.0; var riskPct=0.5; var maxPositionPct=20.0; var maxPositions=5
    var momentumMonths=12; var fastMA=50; var slowMA=200; var minimumScore=80; var atrStop=2.0; var trailingATR=2.5
    var useRSI=true; var useMACD=true; var useADX=true; var useVolume=true
}
struct ScanResult: Identifiable { let asset:Asset; let price:Double; let score:Int; let momentum:Double; let above200:Bool; let rsi:Double; let reason:String; var id:String{asset.symbol} }
