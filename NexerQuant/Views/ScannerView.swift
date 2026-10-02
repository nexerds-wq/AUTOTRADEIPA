import SwiftUI

struct ScannerView: View {
    @EnvironmentObject var s: TradingStore
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing:12) {
                    if s.scans.isEmpty {
                        ContentUnavailableView("No Research Scan Yet",systemImage:"scope",description:Text("Run a scan from Command Center to rank the available market signals."))
                    } else {
                        ForEach(Array(s.scans.enumerated()),id:\.element.id) { index,x in
                            VStack(alignment:.leading,spacing:10) {
                                HStack {
                                    ZStack { Circle().fill(.thinMaterial).frame(width:42,height:42); Text("\(index+1)").font(.headline.bold()) }
                                    VStack(alignment:.leading){Text(x.asset.symbol).font(.title3.bold());Text(x.asset.name).font(.caption).foregroundStyle(.secondary)}
                                    Spacer()
                                    Text("\(x.score)").font(.title.bold()).contentTransition(.numericText())
                                }
                                HStack { chip(x.above200 ? "ABOVE 200D":"BELOW 200D"); chip(x.breakout ? "BREAKOUT":"NO BREAKOUT"); chip("VOL \(x.volatility,specifier:"%.1f")%") }
                                Text(x.reason).font(.caption).foregroundStyle(.secondary)
                                ProgressView(value:Double(x.score),total:100).tint(x.score>=80 ? .green : x.score>=60 ? .orange:.secondary)
                            }
                            .padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20))
                            .transition(.move(edge:.bottom).combined(with:.opacity))
                        }
                    }
                }.padding()
            }.navigationTitle("Signal Radar")
        }
    }
    func chip(_ t:String)->some View { Text(t).font(.caption2.bold()).padding(.horizontal,8).padding(.vertical,5).background(.quaternary,in:Capsule()) }
}
