import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var s: TradingStore
    @State private var pulse=false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:18) {
                    HStack {
                        VStack(alignment:.leading,spacing:4) {
                            Text("NEXER QUANT").font(.largeTitle.bold())
                            Text("MOMENTUM RESEARCH LAB").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle().fill(s.isScanning ? .orange:.green).frame(width:12,height:12)
                            .scaleEffect(pulse ? 1.35:0.85)
                            .animation(.easeInOut(duration:0.9).repeatForever(),value:pulse)
                    }
                    .onAppear{pulse=true}

                    HStack(spacing:12) {
                        metric("PAPER EQUITY",s.equity.formatted(.currency(code:"USD")),"chart.line.uptrend.xyaxis")
                        metric("CASH",s.cash.formatted(.currency(code:"USD")),"banknote")
                    }

                    VStack(alignment:.leading,spacing:12) {
                        HStack { Text("Research Engine").font(.headline); Spacer(); Text(s.isScanning ? "ANALYZING":"READY").font(.caption.bold()).foregroundStyle(s.isScanning ? .orange:.green) }
                        ProgressView(value:s.isScanning ? 0.72:1).tint(s.isScanning ? .orange:.green)
                        Text("Ranks trend, momentum, volatility and breakout evidence. Results are simulated and meant for validation before any real-money use.").font(.caption).foregroundStyle(.secondary)
                        Button { Task { await s.scan() } } label: {
                            Label(s.isScanning ? "Scanning Market…":"Run Research Scan",systemImage:"waveform.path.ecg")
                                .frame(maxWidth:.infinity).padding(.vertical,6)
                        }.buttonStyle(.borderedProminent).disabled(s.isScanning)
                    }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:22))

                    if let best=s.scans.first {
                        VStack(alignment:.leading,spacing:10) {
                            Text("TOP SIGNAL").font(.caption.bold()).foregroundStyle(.secondary)
                            HStack(alignment:.firstTextBaseline) { Text(best.asset.symbol).font(.system(size:34,weight:.black)); Spacer(); Text("\(best.score)").font(.system(size:34,weight:.black)); Text("/100").foregroundStyle(.secondary) }
                            Text(best.asset.name).foregroundStyle(.secondary)
                            HStack { badge("12M \(best.momentum12,specifier:"%.1f")%"); badge("6M \(best.momentum6,specifier:"%.1f")%"); badge(best.breakout ? "BREAKOUT":"TREND") }
                            Text(best.reason).font(.caption).foregroundStyle(.secondary)
                        }.padding().background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:22))
                        .transition(.scale.combined(with:.opacity))
                    }

                    VStack(alignment:.leading,spacing:10) {
                        Text("SYSTEM STATUS").font(.caption.bold()).foregroundStyle(.secondary)
                        status("Keyless market history",true)
                        status("Paper execution only",true)
                        status("Risk analytics",true)
                        status("Real-money broker connected",false)
                    }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:22))
                }.padding()
            }.navigationTitle("Command Center")
        }
    }

    func metric(_ title:String,_ value:String,_ icon:String)->some View { VStack(alignment:.leading,spacing:8){Image(systemName:icon).font(.title2);Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.title3.bold())}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) }
    func badge(_ text:String)->some View { Text(text).font(.caption2.bold()).padding(.horizontal,9).padding(.vertical,6).background(.quaternary,in:Capsule()) }
    func status(_ text:String,_ good:Bool)->some View { HStack { Image(systemName:good ? "checkmark.circle.fill":"minus.circle").foregroundStyle(good ? .green:.secondary);Text(text);Spacer() } }
}
