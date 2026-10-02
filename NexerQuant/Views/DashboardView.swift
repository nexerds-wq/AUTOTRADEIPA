import SwiftUI

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
                            .scaleEffect(pulse ? 1.25:0.9)
                            .animation(.easeInOut(duration:0.9).repeatForever(),value:pulse)
                    }.onAppear{pulse=true}

                    HStack(spacing:12) {
                        metric("PAPER EQUITY",money(s.equity),"chart.line.uptrend.xyaxis")
                        metric("CASH",money(s.cash),"banknote")
                    }

                    VStack(alignment:.leading,spacing:12) {
                        HStack {
                            Text("Research Engine").font(.headline)
                            Spacer()
                            Text(s.isScanning ? "ANALYZING":"READY").font(.caption.bold()).foregroundStyle(s.isScanning ? .orange:.green)
                        }
                        if s.isScanning { ProgressView() }
                        Text(s.scanStatus).font(.caption).foregroundStyle(.secondary)
                        Text("Ranks trend, momentum, volatility and breakout evidence using paper trading.").font(.caption).foregroundStyle(.secondary)
                        Button(action:startScan) {
                            Label(s.isScanning ? "Scanning Market…":"Run Research Scan",systemImage:"waveform.path.ecg")
                                .frame(maxWidth:.infinity).padding(.vertical,7)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(s.isScanning)
                    }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:22))

                    if let best=s.scans.first {
                        VStack(alignment:.leading,spacing:10) {
                            Text("TOP SIGNAL").font(.caption.bold()).foregroundStyle(.secondary)
                            HStack { Text(best.asset.symbol).font(.system(size:32,weight:.black)); Spacer(); Text("\(best.score)/100").font(.title.bold()) }
                            Text(best.asset.name).foregroundStyle(.secondary)
                            Text(best.reason).font(.caption).foregroundStyle(.secondary)
                        }.padding().background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:22))
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

    private func startScan() {
        guard !s.isScanning else { return }
        Task { @MainActor in await s.scan() }
    }
    private func money(_ x:Double)->String { guard x.isFinite else{return "$0.00"};return String(format:"$%.2f",x) }
    private func metric(_ title:String,_ value:String,_ icon:String)->some View { VStack(alignment:.leading,spacing:8){Image(systemName:icon).font(.title2);Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.title3.bold())}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) }
    private func status(_ text:String,_ good:Bool)->some View { HStack{Image(systemName:good ? "checkmark.circle.fill":"minus.circle").foregroundStyle(good ? .green:.secondary);Text(text);Spacer()} }
}
