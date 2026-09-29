import Foundation

actor MarketDataService {
    // Plug-and-play demo feed. Add a Twelve Data API key in Settings for live candles.
    func candles(symbol:String, apiKey:String) async throws -> [Double] {
        if !apiKey.isEmpty {
            let encoded=symbol.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) ?? symbol
            let u="https://api.twelvedata.com/time_series?symbol=\(encoded)&interval=1day&outputsize=365&apikey=\(apiKey)"
            if let url=URL(string:u) {
                let (data,_)=try await URLSession.shared.data(from:url)
                struct R:Decodable { struct V:Decodable{let close:String}; let values:[V]? }
                if let r=try? JSONDecoder().decode(R.self,from:data), let v=r.values, !v.isEmpty { return v.reversed().compactMap{Double($0.close)} }
            }
        }
        var rng=Seeded(seed: UInt64(abs(symbol.hashValue))+1); var p=50+Double(abs(symbol.hashValue)%250); var out:[Double]=[]
        for _ in 0..<365 { p=max(1,p*(1 + Double.random(in:-0.025...0.027,using:&rng))); out.append(p) }; return out
    }
}
struct Seeded:RandomNumberGenerator { var state:UInt64; init(seed:UInt64){state=seed}; mutating func next()->UInt64{state=2862933555777941757 &* state &+ 3037000493; return state} }
