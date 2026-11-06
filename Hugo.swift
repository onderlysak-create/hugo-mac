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

// Gothic illustrated scene, drawn natively so no external images are needed.
private let parchment = Color(red: 0.88, green: 0.81, blue: 0.69)
private let ink = Color(red: 0.10, green: 0.09, blue: 0.13)
private let lilac = Color(red: 0.73, green: 0.61, blue: 0.79)

struct SpookyScene: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.10, green: 0.12, blue: 0.18), Color(red: 0.24, green: 0.25, blue: 0.33), Color(red: 0.10, green: 0.10, blue: 0.14)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(red: 0.94, green: 0.87, blue: 0.70)).frame(width: 175, height: 175)
                    .blur(radius: 4).shadow(color: parchment.opacity(0.45), radius: 35)
                    .position(x: geo.size.width * 0.34, y: 130)
                // The crooked house on the distant hill
                Path { path in
                    let x = geo.size.width * 0.81
                    path.move(to: CGPoint(x: x-42, y: 270)); path.addLine(to: CGPoint(x: x-37, y: 173))
                    path.addLine(to: CGPoint(x: x-60, y: 190)); path.addLine(to: CGPoint(x: x-7, y: 115))
                    path.addLine(to: CGPoint(x: x+42, y: 190)); path.addLine(to: CGPoint(x: x+22, y: 176))
                    path.addLine(to: CGPoint(x: x+39, y: 270)); path.closeSubpath()
                }.fill(ink)
                RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.98, green: 0.74, blue: 0.37))
                    .frame(width: 13, height: 27).rotationEffect(.degrees(8))
                    .position(x: geo.size.width * 0.81, y: 209)
                    .shadow(color: .orange.opacity(0.8), radius: 12)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 335))
                    path.addCurve(to: CGPoint(x: geo.size.width, y: 318), control1: CGPoint(x: 220, y: 245), control2: CGPoint(x: 500, y: 300))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height)); path.addLine(to: CGPoint(x: 0, y: geo.size.height)); path.closeSubpath()
                }.fill(Color(red: 0.14, green: 0.15, blue: 0.19))
                // Twisted tree silhouettes
                tree(x: 0.10, width: geo.size.width, height: geo.size.height, flip: false)
                tree(x: 0.95, width: geo.size.width, height: geo.size.height, flip: true)
                VStack { Spacer(); Rectangle().fill(Color.black.opacity(0.22)).frame(height: 3); Rectangle().fill(Color(red: 0.13, green: 0.12, blue: 0.14)).frame(height: 115) }
            }.clipped()
        }
    }
    func tree(x: CGFloat, width: CGFloat, height: CGFloat, flip: Bool) -> some View {
        Path { path in
            let base = width*x, dir: CGFloat = flip ? -1 : 1
            path.move(to: CGPoint(x: base-13, y: height*0.76))
            path.addQuadCurve(to: CGPoint(x: base+4, y: 125), control: CGPoint(x: base+dir*30, y: 230))
            path.addQuadCurve(to: CGPoint(x: base+dir*95, y: 52), control: CGPoint(x: base+dir*65, y: 95))
            path.addQuadCurve(to: CGPoint(x: base+dir*28, y: 145), control: CGPoint(x: base+dir*75, y: 85))
            path.addQuadCurve(to: CGPoint(x: base+dir*130, y: 192), control: CGPoint(x: base+dir*85, y: 172))
            path.addQuadCurve(to: CGPoint(x: base+dir*22, y: 177), control: CGPoint(x: base+dir*73, y: 193))
            path.addLine(to: CGPoint(x: base+18, y: height*0.76)); path.closeSubpath()
        }.fill(Color(red: 0.065, green: 0.065, blue: 0.09))
    }
}

struct DogView: View {
    let sleeping: Bool
    @State private var bounce = false
    @State private var blink = false
    @State private var stepForward = false
    @State private var earTwitch = false
    let walking: Bool
    private let motionTimer = Timer.publish(every: 0.28, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 3.7, on: .main, in: .common).autoconnect()
    private let fur = Color(red: 0.19, green: 0.18, blue: 0.21)
    private let shade = Color(red: 0.12, green: 0.11, blue: 0.14)
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.5)).frame(width: 240, height: 25).offset(y: 135)
            // Back paws and body
            Ellipse().fill(shade).frame(width: 175, height: 150).offset(y: 55)
            Ellipse().fill(fur).frame(width: 200, height: 193).offset(y: -22)
            ear(-76, angle: -19).rotationEffect(.degrees(earTwitch ? -5 : 0), anchor: .bottom)
            ear(76, angle: 19).rotationEffect(.degrees(earTwitch ? 5 : 0), anchor: .bottom)
            Ellipse().fill(Color(red: 0.28, green: 0.26, blue: 0.29)).frame(width: 91, height: 86).offset(y: 38)
            if sleeping {
                Text("⌣         ⌣").font(.system(size: 37, weight: .bold)).foregroundColor(parchment).offset(y: -38)
                Text("Z z z").font(.system(size: 28, design: .serif)).foregroundColor(lilac).offset(x: 138, y: -125)
            } else if blink {
                Capsule().fill(parchment).frame(width: 54, height: 7).offset(x: -48, y: -44)
                Capsule().fill(parchment).frame(width: 54, height: 7).offset(x: 48, y: -44)
            } else {
                eye(-48); eye(48)
            }
            Ellipse().fill(.black).frame(width: 62, height: 39).offset(y: 11)
            Ellipse().stroke(shade, lineWidth: 3).frame(width: 48, height: 26).offset(y: 45)
            Text("ᴗ").font(.system(size: 27, weight: .heavy)).foregroundColor(.black).offset(y: 53)
            RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.44, green: 0.28, blue: 0.35)).frame(width: 139, height: 20).offset(y: 88)
            Circle().fill(Color(red: 0.75, green: 0.59, blue: 0.34)).frame(width: 42, height: 42).offset(y: 105)
            Text("HUGO").font(.system(size: 13, weight: .black, design: .serif)).foregroundColor(ink).offset(y: 105)
            Ellipse().fill(fur).frame(width: 51, height: 35)
                .rotationEffect(.degrees(walking && stepForward ? 18 : -6))
                .offset(x: -65, y: walking && stepForward ? 115 : 130)
            Ellipse().fill(fur).frame(width: 51, height: 35)
                .rotationEffect(.degrees(walking && !stepForward ? -18 : 6))
                .offset(x: 65, y: walking && !stepForward ? 115 : 130)
        }
        .frame(width: 340, height: 350)
        .scaleEffect(bounce ? 1.0 : 0.98)
        .offset(y: walking ? (stepForward ? -7 : 1) : (bounce ? -3 : 3))
        .animation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true), value: bounce)
        .animation(.easeInOut(duration: 0.24), value: stepForward)
        .animation(.easeInOut(duration: 0.24), value: earTwitch)
        .onAppear { bounce = true }
        .onReceive(motionTimer) { _ in
            if walking { stepForward.toggle() }
            if Int.random(in: 0..<11) == 0 { earTwitch.toggle() }
        }
        .onReceive(blinkTimer) { _ in
            guard !sleeping else { return }
            blink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { blink = false }
        }
    }
    func ear(_ x: CGFloat, angle: Double) -> some View {
        ZStack {
            Ellipse().fill(shade).frame(width: 83, height: 148)
            Ellipse().fill(Color(red: 0.48, green: 0.32, blue: 0.38)).frame(width: 48, height: 103)
        }.rotationEffect(.degrees(angle)).offset(x: x, y: -126)
    }
    func eye(_ x: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(parchment).frame(width: 60, height: 70)
            Circle().fill(ink).frame(width: 33, height: 38).offset(x: 7, y: 5)
            Circle().fill(.white).frame(width: 11, height: 11).offset(x: 0, y: -8)
        }.offset(x: x, y: -44)
    }
}

struct ContentView: View {
    @ObservedObject var model: HugoModel
    let goWalk: () -> Void
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            SpookyScene()
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("🐾 HUGO").font(.system(size: 38, weight: .black, design: .serif))
                        .foregroundColor(parchment).shadow(color: .black, radius: 5)
                    Text("MY LITTLE MONSTER").font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(3).foregroundColor(lilac)
                    Spacer()
                    Text(model.message).font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(parchment).padding(12)
                        .background(ink.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(width: 190)
                Spacer(minLength: 0)
                VStack(spacing: 13) {
                    Text("HUGOVY POTŘEBY").font(.system(size: 16, weight: .bold, design: .serif)).tracking(2).foregroundColor(parchment)
                    meter("🍖 Hlad", model.pet.hunger)
                    meter("❤️ Radost", model.pet.happiness)
                    meter("🌙 Energie", model.pet.energy)
                    meter("🫧 Čistota", model.pet.cleanliness)
                    Divider().overlay(parchment.opacity(0.3))
                    Toggle("Zvukové projevy", isOn: $model.sound).toggleStyle(.checkbox).foregroundColor(parchment)
                }
                .padding(16).frame(width: 244)
                .background(ink.opacity(0.87), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(parchment.opacity(0.45), lineWidth: 1.5))
            }
            .padding(22)
            .frame(maxHeight: .infinity, alignment: .top)
            DogView(sleeping: model.asleep, walking: false).scaleEffect(1.10).offset(x: -15, y: 30)
                .onTapGesture { model.act("Pohlaď") }
            VStack {
                Spacer()
                HStack(spacing: 9) {
                    action("🍖 Nakrmit", "Nakrm")
                    action("🎾 Hrát", "Hraj")
                    action("❤️ Pohladit", "Pohlaď")
                    action("🫧 Vykoupat", "Vykoupej")
                    action(model.asleep ? "☀️ Vzbudit" : "🌙 Spát", "Spi")
                    Button("🐾 Procházka") { goWalk() }.buttonStyle(GothicButtonStyle())
                }.padding(.horizontal, 16)
                Text("Klikni na Huga a pohlaď ho  •  Stav se ukládá automaticky")
                    .font(.system(size: 11)).foregroundColor(parchment.opacity(0.7)).padding(.top, 12)
            }.padding(.bottom, 22)
        }
        .frame(width: 880, height: 590)
        .onReceive(timer) { _ in model.tick() }
    }
    func meter(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text(label); Spacer(); Text("\(Int(value)) %") }
                .font(.system(size: 13, weight: .medium)).foregroundColor(parchment)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(lilac).frame(width: max(0, g.size.width * CGFloat(value / 100)))
                }
            }.frame(height: 10)
        }
    }
    func action(_ label: String, _ key: String) -> some View {
        Button(label) { model.act(key) }.buttonStyle(GothicButtonStyle())
    }
}

struct GothicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .serif))
            .foregroundColor(ink)
            .padding(.horizontal, 10).frame(height: 50)
            .background(parchment.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(ink.opacity(0.8), lineWidth: 2))
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
        window = NSWindow(contentRect: NSRect(x: 150, y: 150, width: 880, height: 590), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
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
        w.contentView = NSHostingView(rootView: DogView(sleeping: false, walking: true).scaleEffect(0.65).frame(width: 220, height: 230))
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
