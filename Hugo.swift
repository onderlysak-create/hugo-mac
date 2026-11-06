import Cocoa
import SwiftUI
import AVFoundation

struct PetState: Codable {
    var hunger: Double = 75
    var happiness: Double = 80
    var energy: Double = 85
    var cleanliness: Double = 90
    var lastUpdated: Date = Date()
}

final class HugoModel: ObservableObject {
    @Published var pet = PetState()
    @Published var message = "Ahoj! Já jsem Hugo. 🐾"
    @Published var asleep = false
    @Published var sound = true
    @Published var walking = false
    private var audio: AVAudioPlayer?
    private let key = "HugoPetStateV1"
    init() {
        if let data = UserDefaults.standard.data(forKey: key), let p = try? JSONDecoder().decode(PetState.self, from: data) { pet = p }
        let hours = min(48, max(0, Date().timeIntervalSince(pet.lastUpdated) / 3600))
        pet.hunger = max(0, pet.hunger - hours * 2.5)
        pet.happiness = max(0, pet.happiness - hours * 1.5)
        pet.energy = max(0, pet.energy - hours * 1.0)
        save()
    }
    func save() { pet.lastUpdated = Date(); if let d = try? JSONEncoder().encode(pet) { UserDefaults.standard.set(d, forKey: key) } }
    func act(_ action: String) {
        switch action {
        case "Nakrm": pet.hunger = min(100, pet.hunger + 24); message = "Mňam! To bylo dobré!"; tone(190)
        case "Hraj": pet.happiness = min(100, pet.happiness + 22); pet.energy = max(0, pet.energy - 12); pet.hunger = max(0, pet.hunger - 8); message = "Házej míček! Haf!"; tone(410)
        case "Pohlaď": pet.happiness = min(100, pet.happiness + 12); message = "Chrocht, chrocht… ❤️"; tone(145)
        case "Vykoupej": pet.cleanliness = 100; message = "Teď krásně voním!"; tone(500)
        case "Spi": asleep.toggle(); pet.energy = min(100, pet.energy + (asleep ? 28 : 0)); message = asleep ? "Chrrrr… zzz…" : "Už jsem vzhůru!"; tone(120)
        default: break
        }
        save()
    }
    func tick() {
        if !asleep { pet.hunger = max(0, pet.hunger - 0.12); pet.energy = max(0, pet.energy - 0.07); pet.cleanliness = max(0, pet.cleanliness - 0.04) }
        else { pet.energy = min(100, pet.energy + 0.3) }
        if pet.hunger < 20 { message = "Mám hlad… 🥺" }
        save()
    }
    func tone(_ frequency: Double) {
        guard sound else { return }
        let sampleRate = 22050.0, duration = 0.18
        let count = Int(sampleRate * duration)
        var pcm = Data(capacity: count * 2)
        for i in 0..<count {
            let envelope = pow(1.0 - Double(i)/Double(count), 2)
            let v = Int16(sin(2 * .pi * frequency * Double(i) / sampleRate) * 6500 * envelope)
            var little = v.littleEndian
            withUnsafeBytes(of: &little) { pcm.append(contentsOf: $0) }
        }
        let headerSize = UInt32(36 + pcm.count)
        var wav = Data()
        func str(_ s: String) { wav.append(contentsOf: s.utf8) }
        func u32(_ x: UInt32) { var a = x.littleEndian; withUnsafeBytes(of: &a) { wav.append(contentsOf: $0) } }
        func u16(_ x: UInt16) { var a = x.littleEndian; withUnsafeBytes(of: &a) { wav.append(contentsOf: $0) } }
        str("RIFF"); u32(headerSize); str("WAVEfmt "); u32(16); u16(1); u16(1); u32(UInt32(sampleRate)); u32(UInt32(sampleRate * 2)); u16(2); u16(16); str("data"); u32(UInt32(pcm.count)); wav.append(pcm)
        audio = try? AVAudioPlayer(data: wav); audio?.play()
    }
}

struct DogView: View {
    let sleeping: Bool
    @State private var bounce = false
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.3)).frame(width: 180, height: 25).offset(y: 104)
            Ellipse().fill(Color(red: 0.20, green: 0.19, blue: 0.23)).frame(width: 145, height: 120).offset(y: 54)
            Ellipse().fill(Color(red: 0.28, green: 0.26, blue: 0.32)).frame(width: 173, height: 150).offset(y: -22)
            ear(-65, angle: -16); ear(65, angle: 16)
            Ellipse().fill(Color(red: 0.38, green: 0.34, blue: 0.40)).frame(width: 75, height: 65).offset(y: 24)
            if sleeping {
                Text("﹀       ﹀").font(.system(size: 35, weight: .bold)).foregroundColor(.white).offset(y: -37)
                Text("Z z z").font(.title).foregroundColor(.purple.opacity(0.8)).offset(x: 125, y: -105)
            } else {
                eye(-42); eye(42)
            }
            Ellipse().fill(Color.black).frame(width: 50, height: 31).offset(y: 7)
            Text("ᴗ").font(.system(size: 34, weight: .bold)).foregroundColor(.black).offset(y: 39)
            RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.54, green: 0.29, blue: 0.42)).frame(width: 110, height: 17).offset(y: 67)
            Text("HUGO").font(.system(size: 12, weight: .black, design: .serif)).foregroundColor(.white).padding(6).background(Circle().fill(Color(red: 0.75, green: 0.61, blue: 0.34))).offset(y: 84)
        }
        .frame(width: 300, height: 270)
        .offset(y: bounce ? -5 : 3)
        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: bounce)
        .onAppear { bounce = true }
    }
    func ear(_ x: CGFloat, angle: Double) -> some View {
        ZStack { Ellipse().fill(Color(red: 0.23, green: 0.21, blue: 0.27)).frame(width: 68, height: 116)
            Ellipse().fill(Color(red: 0.54, green: 0.32, blue: 0.42)).frame(width: 39, height: 77) }
        .rotationEffect(.degrees(angle)).offset(x: x, y: -101)
    }
    func eye(_ x: CGFloat) -> some View {
        ZStack { Ellipse().fill(Color.white).frame(width: 49, height: 57)
            Circle().fill(Color(red: 0.18, green: 0.15, blue: 0.22)).frame(width: 27, height: 30).offset(x: 5, y: 3)
            Circle().fill(.white).frame(width: 9, height: 9).offset(x: 1, y: -5) }
        .offset(x: x, y: -43)
    }
}

struct ContentView: View {
    @ObservedObject var model: HugoModel
    let goWalk: () -> Void
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.16), Color(red: 0.24, green: 0.18, blue: 0.27)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 8) {
                Text("HUGO").font(.system(size: 38, weight: .black, design: .serif)).tracking(6).foregroundColor(.white)
                Text("MY LITTLE MONSTER").font(.caption).tracking(4).foregroundColor(.gray)
                DogView(sleeping: model.asleep).onTapGesture { model.act("Pohlaď") }
                Text(model.message).font(.system(size: 16, design: .serif)).foregroundColor(.white).frame(height: 28)
                VStack(spacing: 8) {
                    meter("🍖 Hlad", model.pet.hunger, .orange)
                    meter("❤️ Radost", model.pet.happiness, .pink)
                    meter("🌙 Energie", model.pet.energy, .purple)
                    meter("🫧 Čistota", model.pet.cleanliness, .cyan)
                }.padding(.horizontal, 35)
                HStack(spacing: 8) {
                    action("🍖 Nakrmit", "Nakrm")
                    action("🎾 Hrát", "Hraj")
                    action("❤️ Pohladit", "Pohlaď")
                }
                HStack(spacing: 8) {
                    action("🫧 Vykoupat", "Vykoupej")
                    action(model.asleep ? "☀️ Vzbudit" : "🌙 Spát", "Spi")
                    Button("🐾 Procházka") { goWalk() }.buttonStyle(.borderedProminent).tint(.purple)
                }
                Toggle("Zvukové projevy", isOn: $model.sound).toggleStyle(.checkbox).foregroundColor(.white).padding(.top, 5)
                Text("Klikni na Huga a pohlaď ho • Stav se ukládá automaticky")
                    .font(.system(size: 11)).foregroundColor(.gray)
            }.padding(18)
        }
        .frame(width: 500, height: 690)
        .onReceive(timer) { _ in model.tick() }
    }
    func meter(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack { Text(label).frame(width: 95, alignment: .leading)
            GeometryReader { g in ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(color).frame(width: max(0, g.size.width * CGFloat(value / 100)))
            }}.frame(height: 12)
            Text("\(Int(value))%").frame(width: 45, alignment: .trailing)
        }.font(.system(size: 13)).foregroundColor(.white)
    }
    func action(_ label: String, _ key: String) -> some View {
        Button(label) { model.act(key) }.buttonStyle(.bordered).tint(.white)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var walkWindow: NSWindow?
    let model = HugoModel()
    var steps = 0
    var walkTimer: Timer?
    var idleTimer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = ContentView(model: model, goWalk: { [weak self] in self?.walk() })
        window = NSWindow(contentRect: NSRect(x: 150, y: 150, width: 500, height: 690), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Hugo – My Little Monster"
        window.contentView = NSHostingView(rootView: content)
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        idleTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            guard let self = self, !self.model.asleep, self.walkWindow == nil else { return }
            if Int.random(in: 0..<3) == 0 { self.walk() }
        }
    }
    func walk() {
        guard walkWindow == nil, let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        let w = NSWindow(contentRect: NSRect(x: area.minX - 220, y: area.minY + 8, width: 220, height: 230), styleMask: [.borderless], backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.hasShadow = false
        w.level = .floating; w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.contentView = NSHostingView(rootView: DogView(sleeping: false).scaleEffect(0.65).frame(width: 220, height: 230))
        w.orderFrontRegardless(); walkWindow = w
        model.message = "Hugo vyrazil na výpravu! 🐾"; model.tone(320)
        steps = 0
        walkTimer = Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { [weak self] timer in
            guard let self = self, let ww = self.walkWindow else { timer.invalidate(); return }
            var frame = ww.frame; frame.origin.x += 5; ww.setFrameOrigin(frame.origin)
            self.steps += 1
            if self.steps % 28 == 0 { self.model.tone(180) }
            if frame.minX > area.maxX { timer.invalidate(); ww.close(); self.walkWindow = nil; self.model.message = "Už jsem zpátky doma!" }
        }
    }
    func applicationWillTerminate(_ notification: Notification) { model.save() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main struct HugoApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
