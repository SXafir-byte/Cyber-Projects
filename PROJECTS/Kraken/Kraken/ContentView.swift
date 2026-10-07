import SwiftUI
import AVKit
import SceneKit

struct VideoBackgroundView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        view.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

class InteractiveSCNView: SCNView {
    var modelNode: SCNNode?
    var originalScale: SCNVector3 = SCNVector3(0.2, 0.2, 0.2)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        self.trackingAreas.forEach { self.removeTrackingArea($0) }

        let options: NSTrackingArea.Options = [.mouseMoved, .activeInActiveApp, .inVisibleRect, .mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        guard let node = modelNode else { return }
        let location = convert(event.locationInWindow, from: nil)
        let bounds = self.bounds
        let x = (location.x - bounds.midX) / bounds.width
        let y = (location.y - bounds.midY) / bounds.height
        let maxAngle: Float = .pi / 8

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        node.eulerAngles = SCNVector3(-Float(y) * maxAngle, Float(x) * maxAngle, 0)
        SCNTransaction.commit()
    }

    override func mouseDown(with event: NSEvent) {
        guard let node = modelNode else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        node.scale = SCNVector3(originalScale.x * 0.9, originalScale.y * 0.9, originalScale.z * 0.9)
        SCNTransaction.commit()
    }

    override func mouseUp(with event: NSEvent) {
        guard let node = modelNode else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        node.scale = originalScale
        SCNTransaction.commit()
    }
}

// MARK: - Sidebar 3D Model View
struct SidebarModelView: NSViewRepresentable {
    let modelName: String

    func makeNSView(context: Context) -> InteractiveSCNView {
        let sceneView = InteractiveSCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        guard let modelScene = SCNScene(named: modelName) else { return sceneView }

        let rootNode = SCNNode()
        for child in modelScene.rootNode.childNodes {
            rootNode.addChildNode(child)
        }

        rootNode.scale = SCNVector3(0.2, 0.2, 0.2)
        rootNode.position = SCNVector3(0, -2, 0)
        sceneView.originalScale = rootNode.scale
        sceneView.modelNode = rootNode
        sceneView.scene?.rootNode.addChildNode(rootNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        return sceneView
    }

    func updateNSView(_ nsView: InteractiveSCNView, context: Context) {}
}

// MARK: - Helix Spinner Animation
struct HelixSpinner: View {
    let ballCount = 50
    let amplitude: CGFloat = 30
    let speed: Double = 2

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            TimelineView(.animation) { timeline in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                let phase = CGFloat(currentTime * (2 * .pi) / speed)

                ZStack {
                    ForEach(0..<ballCount, id: \.self) { i in
                        let progress = CGFloat(i) / CGFloat(ballCount - 1) // note: ballCount-1 for full span
                        let angle = progress * .pi * 2 + phase
                        let y = sin(angle) * amplitude
                        let x = progress * width // x goes from 0 to width
                        let z = cos(angle)

                        Circle()
                            .fill(Color.accentColor.opacity(0.7 + 0.3 * z))
                            .frame(width: 12, height: 12)
                            .offset(x: x, y: y)
                            .zIndex(z)
                    }

                    ForEach(0..<ballCount, id: \.self) { i in
                        let progress = CGFloat(i) / CGFloat(ballCount - 1)
                        let angle = progress * .pi * 2 + phase + .pi
                        let y = sin(angle) * amplitude
                        let x = progress * width
                        let z = cos(angle)

                        Circle()
                            .fill(Color.accentColor.opacity(0.7 + 0.3 * z))
                            .frame(width: 12, height: 12)
                            .offset(x: x, y: y)
                            .zIndex(z)
                    }
                }
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var output: String = ""
    @State private var target: String = ""
    @State private var startPort: String = ""
    @State private var endPort: String = ""
    @State private var scriptPath: String = "/Users/jakubk08/Swift-Projects/Kraken/Kraken/Kraken/Scanner.pyt"
    @State private var scriptPath2: String = "/Users/jakubk08/Pyt-Port-Scan/Listener.pyt"
    @State private var showOutputArea = false
    @State private var isRunning = false
    @State private var player = AVPlayer()
    @State private var rotationAngle = 0.0
    @State private var mode: String = "scanner" // "scanner" or "listener"
    @State private var listenerIP: String = ""
    @State private var listenerPort: String = ""

    // Hold reference to the currently running process so we can terminate it
    @State private var runningProcess: Process?

    var body: some View {
        ZStack {
            VideoBackgroundView(player: player)
                .ignoresSafeArea()
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            HStack {
                VStack(spacing: 20) {
                    SidebarModelView(modelName: "rss_symbol.256.usdz")
                        .frame(width: 60, height: 60)
                        .onTapGesture {
                            stopRunningProcess()
                            mode = "scanner"
                        }
                    Spacer()
                    SidebarModelView(modelName: "rss_symbol.256.usdz")
                        .frame(width: 60, height: 60)
                        .onTapGesture {
                            stopRunningProcess()
                            mode = "listener"
                        }
                    Spacer()
                }
                .padding()
                .frame(width: 100)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()

                VStack(alignment: .leading, spacing: 20) {
                    Text(mode == "scanner" ? "Port Scanner" : "Port Listener")
                        .font(.largeTitle)
                        .bold()

                    TextField("Python Script Path", text: mode == "scanner" ? $scriptPath : $scriptPath2)
                        .textFieldStyle(.roundedBorder)

                    if mode == "scanner" {
                        HStack {
                            TextField("Target IP", text: $target)
                                .textFieldStyle(.roundedBorder)
                            TextField("Start Port", text: $startPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            TextField("End Port", text: $endPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    } else {
                        HStack {
                            TextField("Listen IP", text: $listenerIP)
                                .textFieldStyle(.roundedBorder)
                            TextField("Port", text: $listenerPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }

                    HStack(spacing: 10) {
                        Button(action: {
                            if isRunning {
                                stopRunningProcess()
                            } else {
                                if mode == "scanner" {
                                    runPortScanner()
                                } else {
                                    runListener()
                                }
                            }
                        }) {
                            Text(isRunning ? "Stop" : (mode == "scanner" ? "Run Scan" : "Start Listening"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .cornerRadius(12)
                        .shadow(radius: 5)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                rotationAngle += 360
                                stopRunningProcess()
                                mode = (mode == "scanner") ? "listener" : "scanner"
                                output = ""
                                showOutputArea = false
                            }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .imageScale(.medium)
                                .rotationEffect(.degrees(rotationAngle))
                                .padding(15)
                        }
                        .buttonStyle(.accessoryBar)
                        .controlSize(.large)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    if showOutputArea {
                        ScrollView {
                            Text(output)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .font(.system(.body, design: .monospaced))
                                .shadow(radius: 3)
                        }
                        .frame(height: 200)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if isRunning {
                        HelixSpinner()
                            .frame(height: 50)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
        .onAppear {
            if let url = Bundle.main.url(forResource: "4886546-hd_1920_1080_25fps", withExtension: "mp4") {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
                player.actionAtItemEnd = .none
                player.play()
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
        }
    }

    func runPortScanner() {
        guard !target.isEmpty, let start = Int(startPort), let end = Int(endPort), !scriptPath.isEmpty else {
            output = "Please fill all fields with valid values."
            withAnimation { showOutputArea = true }
            return
        }
        output = "Scanning \(target) from port \(start) to \(end)...\n"
        isRunning = true
        withAnimation { showOutputArea = true }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath, target, String(start), String(end)]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        runningProcess = process

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    output += "\nFailed to run script: \(error.localizedDescription)"
                    isRunning = false
                }
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    output += result
                    isRunning = false
                }
            }
        }
    }

    func runListener() {
        guard !listenerIP.isEmpty, let port = Int(listenerPort), !scriptPath2.isEmpty else {
            output = "Please fill all fields with valid values."
            withAnimation { showOutputArea = true }
            return
        }
        output = "Listening on \(listenerIP):\(port)...\n"
        isRunning = true
        withAnimation { showOutputArea = true }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath2, listenerIP, String(port)]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        runningProcess = process

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    output += "\nFailed to run script: \(error.localizedDescription)"
                    isRunning = false
                }
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    output += result
                    isRunning = false
                }
            }
        }
    }

    func stopRunningProcess() {
        if let proc = runningProcess, proc.isRunning {
            proc.terminate()
            output += "\nProcess terminated by user."
        }
        runningProcess = nil
        isRunning = false
    }
}
