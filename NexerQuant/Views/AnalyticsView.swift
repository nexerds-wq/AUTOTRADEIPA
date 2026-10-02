import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var s: TradingStore
    @State private var animate = false

    private var closed:[Trade] { s.trades.filter { $0.pnl != nil } }
    private var wins:[Trade] { closed.filter { ($0.pnl ?? 0) > 0 } }
    private var losses:[Trade] { closed.filter { ($0.pnl ?? 0) < 0 } }
    private var realized:Double { closed.compactMap{$0.pnl}.reduce(0,+) }
    private var winRate:Double { closed.isEmpty ? 0 : Double(wins.count)/Double(closed.count)*100 }
    private var grossWin:Double { wins.compactMap{$0.pnl}.reduce(0,+) }
    private var grossLoss:Double { abs(losses.compactMap{$0.pnl}.reduce(0,+)) }
    private var profitFactor:Double { grossLoss == 0 ? (grossWin > 0 ? grossWin : 0) : grossWin/grossLoss }
    private var avgWin:Double { wins.isEmpty ? 0 : grossWin/Double(wins.count) }
    private var avgLoss:Double { losses.isEmpty ? 0 : grossLoss/Double(losses.count) }
    private var expectancy:Double { closed.isEmpty ? 0 : realized/Double(closed.count) }
    private var openPnL:Double { s.positions.reduce(0){$0+$1.pnl} }
    private var invested:Double { s.positions.reduce(0){$0+$1.value} }
    private var exposure:Double { s.equity <= 0 ? 0 : invested/s.equity*100 }
    private var largestPosition:Double { s.positions.map{$0.value/max(s.equity,1)*100}.max() ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:16) {
                    HStack(spacing:10) {
                        metric("WIN RATE",String(format:"%.1f%%",winRate),"target")
                        metric("REALIZED",realized.formatted(.currency(code:"USD")),"dollarsign.circle")
                    }
                    HStack(spacing:10) {
                        metric("PROFIT FACTOR",profitFactor == 0 ? "—" : String(format:"%.2f",profitFactor),"chart.bar.xaxis")
                        metric("EXPECTANCY",expectancy.formatted(.currency(code:"USD")),"waveform.path.ecg")
                    }
                    HStack(spacing:10) {
                        metric("AVG WIN",avgWin.formatted(.currency(code:"USD")),"arrow.up.right")
                        metric("AVG LOSS",avgLoss.formatted(.currency(code:"USD")),"arrow.down.right")
                    }

                    VStack(alignment:.leading,spacing:14) {
                        HStack { Text("RISK ENGINE").font(.caption.bold()).foregroundStyle(.secondary); Spacer(); Text(exposure < 75 ? "NORMAL":"HIGH EXPOSURE").font(.caption.bold()).foregroundStyle(exposure < 75 ? .green:.orange) }
                        riskRow("Capital deployed",exposure,100)
                        riskRow("Largest position",largestPosition,25)
                        HStack { Label("Open P/L",systemImage:"chart.line.uptrend.xyaxis"); Spacer(); Text(openPnL.formatted(.currency(code:"USD"))).bold().foregroundStyle(openPnL >= 0 ? .green:.red) }
                        HStack { Label("Closed trades",systemImage:"checkmark.seal"); Spacer(); Text("\(closed.count)").bold() }
                    }.card()

                    VStack(alignment:.leading,spacing:12) {
                        Text("PORTFOLIO HEATMAP").font(.caption.bold()).foregroundStyle(.secondary)
                        if s.positions.isEmpty { Text("No open positions yet.").foregroundStyle(.secondary) }
                        ForEach(s.positions.sorted{$0.value>$1.value}) { p in
                            VStack(spacing:5) {
                                HStack { Text(p.symbol).font(.headline); Spacer(); Text(String(format:"%.1f%%",p.value/max(s.equity,1)*100)).font(.caption.monospacedDigit()); Text(p.pnl.formatted(.currency(code:"USD"))).font(.caption.bold()).foregroundStyle(p.pnl >= 0 ? .green:.red) }
                                ProgressView(value:p.value,total:max(s.equity,1)).scaleEffect(x:animate ? 1:0.1,anchor:.leading)
                            }
                        }
                    }.card()

                    VStack(alignment:.leading,spacing:12) {
                        HStack { Text("TRADE JOURNAL").font(.caption.bold()).foregroundStyle(.secondary); Spacer(); Text("\(s.trades.count) EVENTS").font(.caption2).foregroundStyle(.secondary) }
                        ForEach(s.trades.prefix(50)) { t in
                            HStack {
                                Image(systemName:t.side == "BUY" ? "arrow.down.circle.fill":"arrow.up.circle.fill").foregroundStyle(t.side == "BUY" ? .blue:.purple)
                                VStack(alignment:.leading) { Text("\(t.side)  \(t.symbol)").font(.headline); Text(t.reason).font(.caption).foregroundStyle(.secondary).lineLimit(2); Text(t.date,style:.relative).font(.caption2).foregroundStyle(.tertiary) }
                                Spacer()
                                VStack(alignment:.trailing) { Text(t.price.formatted(.currency(code:"USD"))); if let p=t.pnl { Text(p.formatted(.currency(code:"USD"))).foregroundStyle(p>=0 ? .green:.red) } }
                            }.padding(.vertical,5)
                            Divider()
                        }
                    }.card()
                }.padding()
            }
            .navigationTitle("Quant Lab")
            .onAppear { withAnimation(.spring(response:0.8,dampingFraction:0.8)){animate=true} }
        }
    }

    func metric(_ title:String,_ value:String,_ icon:String)->some View { VStack(alignment:.leading,spacing:8){Image(systemName:icon).font(.title3);Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.title3.bold()).minimumScaleFactor(0.6)}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) }
    func riskRow(_ title:String,_ value:Double,_ ceiling:Double)->some View { VStack(spacing:6){HStack{Text(title);Spacer();Text(String(format:"%.1f%%",value)).font(.caption.bold())};ProgressView(value:min(value,ceiling),total:ceiling).tint(value>ceiling*0.85 ? .orange:.green)} }
}

private extension View { func card()->some View { self.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) } }
