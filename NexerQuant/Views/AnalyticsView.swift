import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var s: TradingStore

    private var closed:[Trade] { s.trades.filter { $0.pnl != nil } }
    private var wins:[Trade] { closed.filter { ($0.pnl ?? 0) > 0 } }
    private var losses:[Trade] { closed.filter { ($0.pnl ?? 0) < 0 } }
    private var realized:Double { closed.compactMap{$0.pnl}.reduce(0,+) }
    private var winRate:Double { closed.isEmpty ? 0 : Double(wins.count)/Double(closed.count)*100 }
    private var grossWin:Double { wins.compactMap{$0.pnl}.reduce(0,+) }
    private var grossLoss:Double { abs(losses.compactMap{$0.pnl}.reduce(0,+)) }
    private var profitFactor:Double { grossLoss == 0 ? (grossWin > 0 ? grossWin : 0) : grossWin/grossLoss }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:16) {
                    HStack(spacing:10) {
                        metric("WIN RATE","\(winRate,specifier:"%.1f")%","target")
                        metric("REALIZED",realized.formatted(.currency(code:"USD")),"dollarsign.circle")
                    }
                    HStack(spacing:10) {
                        metric("CLOSED","\(closed.count)","checkmark.circle")
                        metric("PROFIT FACTOR",profitFactor == 0 ? "—" : String(format:"%.2f",profitFactor),"chart.bar.xaxis")
                    }

                    VStack(alignment:.leading,spacing:12) {
                        Text("PORTFOLIO EXPOSURE").font(.caption.bold()).foregroundStyle(.secondary)
                        ForEach(s.positions) { p in
                            HStack {
                                Text(p.symbol).font(.headline)
                                ProgressView(value:p.value,total:max(s.equity,1))
                                Text("\(p.value/max(s.equity,1)*100,specifier:"%.1f")%").font(.caption.monospacedDigit())
                            }
                        }
                        if s.positions.isEmpty { Text("No open positions yet.").foregroundStyle(.secondary) }
                    }.card()

                    VStack(alignment:.leading,spacing:12) {
                        Text("TRADE JOURNAL").font(.caption.bold()).foregroundStyle(.secondary)
                        ForEach(s.trades.prefix(30)) { t in
                            HStack {
                                VStack(alignment:.leading) { Text("\(t.side)  \(t.symbol)").font(.headline); Text(t.reason).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                                Spacer()
                                VStack(alignment:.trailing) { Text(t.price.formatted(.currency(code:"USD"))); if let p=t.pnl { Text(p.formatted(.currency(code:"USD"))).foregroundStyle(p>=0 ? .green:.red) } }
                            }.padding(.vertical,4)
                            Divider()
                        }
                    }.card()
                }.padding()
            }.navigationTitle("Analytics")
        }
    }

    func metric(_ title:String,_ value:String,_ icon:String)->some View { VStack(alignment:.leading,spacing:8){Image(systemName:icon);Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.title3.bold()).minimumScaleFactor(0.7)}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) }
}

private extension View { func card()->some View { self.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) } }
