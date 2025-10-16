import Foundation
import SwiftUI

final class ContentService {
	static let shared = ContentService()
	private let baseURL = URL(string: "http://127.0.0.1:8777")!
	private var pythonProcess: Process?

	func startPythonServer() {
		guard pythonProcess == nil else { return }

		guard let pythonURL = Bundle.main.url(
			forResource: "python3.14",
			withExtension: nil,
			subdirectory: "Python.framework/Versions/3.14/bin"
		) else {
			fatalError("Python interpreter not found in bundle")
		}
		let scriptPath = Bundle.main.path(forResource: "main", ofType: "py")!

		let process = Process()
		process.executableURL = pythonURL
		process.arguments = [scriptPath]

//		process.arguments = [] // e.g. ["--port", "8777"]
		process.environment = [
			"PYTHONPATH": Bundle.main.resourcePath! + "/site-packages",
//			"TMPDIR": FileManager.default.temporaryDirectory.path,
			"SSL_CERT_FILE": Bundle.main.resourcePath! + "/cert.pem"
		]

		do {
			try process.run()
			pythonProcess = process
			Task {
				// Optional: wait until server responds before continuing
				await waitUntilServerIsReady()
			}
		} catch {
			print("Failed to launch Python server: \(error)")
		}

		// Stop when app quits
		NotificationCenter.default.addObserver(
			forName: NSApplication.willTerminateNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.pythonProcess?.terminate()
		}
	}

	private func waitUntilServerIsReady() async {
		let healthURL = baseURL.appendingPathComponent("health")
		for _ in 0..<50 {
			if (try? await URLSession.shared.data(from: healthURL)) != nil { return }
			try? await Task.sleep(nanoseconds: 100_000_000_000)
		}
		print("Warning: ytserver did not respond in time")
	}

	func search(query: String) async throws -> [Video] {
		await waitUntilServerIsReady()

		let url = baseURL.appendingPathComponent("search")
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		components.queryItems = [URLQueryItem(name: "q", value: query)]
		var req = URLRequest(url: components.url!)
		req.httpMethod = "POST"

		let (data, _) = try await URLSession.shared.data(for: req)
		return try JSONDecoder().decode([Video].self, from: data)
	}

//	TODO: fix return type
	func getVideo(id: String) async throws -> Test {
		let url = baseURL.appendingPathComponent("video/\(id)")
		let req = URLRequest(url: url)

		let (data, _) = try await URLSession.shared.data(for: req)
		return try JSONDecoder().decode(Test.self, from: data)
	}

	func getChannel(id: String) async throws -> Channel {
		let url = baseURL.appendingPathComponent("channel/\(id)")
		let req = URLRequest(url: url)

		let (data, _) = try await URLSession.shared.data(for: req)
		return try JSONDecoder().decode(Channel.self, from: data)
	}

	func getSkipSegments(id: String) async throws -> [SkipSegment]? {
		let url = URL(string: "https://sponsor.ajay.app/api/skipSegments")!
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		components.queryItems = [URLQueryItem(name: "videoID", value: id)]
		var req = URLRequest(url: components.url!)

		let (data, res) = try await URLSession.shared.data(for: req)

		if let httpResponse = res as? HTTPURLResponse {
			switch httpResponse.statusCode {
				case 200:
					return try JSONDecoder().decode([SkipSegment].self, from: data)
				default:
					return nil
			}
		} else {
			return nil
		}
	}
}
