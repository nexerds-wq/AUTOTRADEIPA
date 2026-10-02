import Foundation

enum AssetClass:String,Codable,CaseIterable,Identifiable { case stocks="Stocks",etfs="ETFs"; var id:String{rawValue} }
struct Asset:Identifiable,Codable,Hashable { let symbol:String; let name:String; let assetClass:AssetClass; var id:String{symbol} }
struct Position:Identifiable,Codable { let id:UUID; let symbol:String; var quantity:Double; var entry:Double; var current:Double; var stop:Double; var peak:Double; let opened:Date; var value:Double{quantity*current}; var pnl:Double{(current-entry)*quantity}; var pnlPct:Double{entry == 0 ? 0:(current/entry-1)*100} }
struct Trade:Identifiable,Codable { let id:UUID; let symbol:String; let side:String; let quantity:Double; let price:Double; let date:Date; let reason:String; let pnl:Double? }
struct ScanResult:Identifiable { let asset:Asset; let price:Double; let score:Int; let momentum12:Double; let momentum6:Double; let above200:Bool; let volatility:Double; let breakout:Bool; let reason:String; var id:String{asset.symbol} }
struct StrategySettings:Codable { var autoEnabled=true; var startingCash=10000.0 }
struct EquityPoint:Identifiable { let id=UUID(); let date:Date; let value:Double }
