import Foundation

struct MarketSeries: Sendable {
    let closes:[Double]
    let highs:[Double]
    let lows:[Double]
    let volumes:[Double]
    var last:Double { closes.last ?? 0 }
}

enum MarketDataError: Error { case badURL, badResponse, insufficientData }

actor MarketDataService {
    private let session:URLSession = {
        let c=URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest=12
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration:c)
    }()

    func series(symbol:String) async throws -> MarketSeries {
        let encoded=symbol.addingPercentEncoding(withAllowedCharacters:.urlPathAllowed) ?? symbol
        guard let url=URL(string:"https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?range=2y&interval=1d&includePrePost=false&events=div%2Csplits") else { throw MarketDataError.badURL }
        var req=URLRequest(url:url); req.setValue("Mozilla/5.0 NexerQuant/2.0",forHTTPHeaderField:"User-Agent")
        let (data,response)=try await session.data(for:req)
        guard let http=response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw MarketDataError.badResponse }
        struct Root:Decodable { let chart:Chart; struct Chart:Decodable { let result:[Result]?; struct Result:Decodable { let indicators:Indicators; struct Indicators:Decodable { let quote:[Quote]; struct Quote:Decodable { let close:[Double?]; let high:[Double?]; let low:[Double?]; let volume:[Double?] } } } } }
        let decoded=try JSONDecoder().decode(Root.self,from:data)
        guard let q=decoded.chart.result?.first?.indicators.quote.first else { throw MarketDataError.badResponse }
        var c:[Double]=[],h:[Double]=[],l:[Double]=[],v:[Double]=[]
        for i in 0..<q.close.count { if let cc=q.close[i], i<q.high.count, let hh=q.high[i], i<q.low.count, let ll=q.low[i] { c.append(cc);h.append(hh);l.append(ll);v.append(i<q.volume.count ? (q.volume[i] ?? 0):0) } }
        guard c.count>=260 else { throw MarketDataError.insufficientData }
        return .init(closes:c,highs:h,lows:l,volumes:v)
    }
}
