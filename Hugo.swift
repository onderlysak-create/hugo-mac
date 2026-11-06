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
    private var snore: AVAudioPlayer?
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
        case "Spi": asleep.toggle(); pet.energy = min(100, pet.energy + (asleep ? 28 : 0)); message = asleep ? "Chrrrr… zzz…" : "Už jsem vzhůru!"; if asleep { playSnore() } else { snore?.stop() }
        default: break
        }
        save()
    }
    func playSnore() {
        guard sound, let url = Bundle.main.url(forResource: "HugoSnore", withExtension: "m4a") else { return }
        snore = try? AVAudioPlayer(contentsOf: url)
        snore?.numberOfLoops = -1
        snore?.volume = 0.65
        snore?.play()
    }
    func tick() {
        if !sound { snore?.stop() } else if asleep && snore?.isPlaying != true { playSnore() }
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
    @State private var breathing = false
    @State private var blink = false
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                Image(nsImage: NSImage(contentsOf: Bundle.main.path(forResource: "HugoScene", ofType: "png") ?? "") ?? NSImage())
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: g.size.width, height: g.size.height).clipped()
                // All controls are native SwiftUI elements over the illustrated scene.
                VStack(alignment: .leading, spacing: 8) {
                    Text("HUGOVY POTŘEBY")
                        .font(.system(size: 17, weight: .black, design: .serif)).tracking(1.5)
                        .frame(maxWidth: .infinity)
                    meter("🍗 Hlad", model.pet.hunger)
                    meter("❤️ Radost", model.pet.happiness)
                    meter("⚡ Energie", model.pet.energy)
                    meter("🫧 Čistota", model.pet.cleanliness)
                    Divider().overlay(parchment)
                    Toggle("Zvukové projevy", isOn: $model.sound)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(parchment)
                .padding(13)
                .frame(width: g.size.width * 0.264)
                .background(Color(red: 0.09, green: 0.075, blue: 0.09).opacity(0.97), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(red: 0.68, green: 0.49, blue: 0.28), lineWidth: 2))
                .position(x: g.size.width * 0.839, y: g.size.height * 0.259)

                // Clickable illustrated dog, with subtle breathing and a sleep cue.
                Button { model.act("Pohlaď") } label: {
                    Color.clear.frame(width: g.size.width * 0.44, height: g.size.height * 0.49)
                }
                .buttonStyle(.plain)
                .position(x: g.size.width * 0.47, y: g.size.height * 0.50)
                if model.asleep {
                    Text("Z z z")
                        .font(.system(size: 29, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .purple, radius: 12)
                        .offset(y: breathing ? -11 : 5)
                        .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: breathing)
                        .position(x: g.size.width * 0.69, y: g.size.height * 0.38)
                }
                Text(model.message)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(parchment)
                    .lineLimit(2)
                    .frame(width: g.size.width * 0.175, height: g.size.height * 0.075)
                    .background(ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 9))
                    .position(x: g.size.width * 0.108, y: g.size.height * 0.84)
                HStack(spacing: 0) {
                    action("Nakrm", width: 0.111, g: g)
                    action("Hraj", width: 0.111, g: g)
                    action("Pohlaď", width: 0.111, g: g)
                    action("Vykoupej", width: 0.111, g: g)
                    action("Spi", width: 0.111, g: g)
                    Button(action: goWalk) { Color.clear }
                        .buttonStyle(.plain)
                        .frame(width: g.size.width * 0.111, height: g.size.height * 0.10)
                }
                .position(x: g.size.width * 0.61, y: g.size.height * 0.839)
            }
        }
        .frame(width: 1000, height: 678)
        .onAppear { breathing = true }
        .onReceive(timer) { _ in model.tick() }
        .onReceive(blinkTimer) { _ in blink.toggle() }
    }
    func meter(_ name: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack { Text(name); Spacer(); Text("\(Int(value)) %") }
                .font(.system(size: 13, weight: .semibold, design: .serif))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.16))
                    Capsule().fill(Color(red: 0.77, green: 0.52, blue: 0.91))
                        .frame(width: geo.size.width * CGFloat(max(0, min(100, value))) / 100)
                }
            }.frame(height: 9)
        }
    }
    func action(_ key: String, width: CGFloat, g: GeometryProxy) -> some View {
        Button { model.act(key) } label: { Color.clear }
            .buttonStyle(.plain)
            .frame(width: g.size.width * width, height: g.size.height * 0.10)
    }
}

struct WalkingHugo: View {
    @State private var footstep = false
    private let timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()
    var body: some View {
        Image(nsImage: NSImage(contentsOf: Bundle.main.path(forResource: "HugoWalk", ofType: "png") ?? "") ?? NSImage())
            .resizable().scaledToFit()
            .frame(width: 190, height: 220)
            .offset(y: footstep ? -5 : 3)
            .onReceive(timer) { _ in withAnimation(.easeInOut(duration: 0.17)) { footstep.toggle() } }
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
        window = NSWindow(contentRect: NSRect(x: 150, y: 150, width: 1000, height: 678), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
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
        w.contentView = NSHostingView(rootView: WalkingHugo().frame(width: 220, height: 230))
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
