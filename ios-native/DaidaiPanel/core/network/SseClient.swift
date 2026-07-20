import Foundation

enum SseEvent {
    case message(id: String?, event: String?, data: String)
    case error(Error)
    case connected
    case disconnected
}

final class SseClient: NSObject, URLSessionDataDelegate {
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var isConnected = false
    private var shouldReconnect = true
    private var reconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    private var currentURL: URL?
    private var currentHeaders: [String: String] = [:]
    private var buffer = ""
    private var lastEventId: String?

    private var continuation: AsyncStream<SseEvent>.Continuation?

    var onEvent: ((SseEvent) -> Void)?

    func connect(url: URL, headers: [String: String] = [:], token: String? = nil) -> AsyncStream<SseEvent> {
        currentURL = url
        currentHeaders = headers
        shouldReconnect = true

        var mutableHeaders = headers
        mutableHeaders["Accept"] = "text/event-stream"
        mutableHeaders["Cache-Control"] = "no-cache"
        if let token, !token.isEmpty {
            mutableHeaders["Authorization"] = "Bearer \(token)"
        }
        let userAgentProvider = UserAgentProvider.shared
        mutableHeaders["User-Agent"] = userAgentProvider.userAgent
        for (key, value) in userAgentProvider.clientHeaders {
            mutableHeaders[key] = value
        }
        currentHeaders = mutableHeaders

        return AsyncStream<SseEvent> { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                self?.disconnect()
            }
            self.doConnect()
        }
    }

    func connect(urlString: String, headers: [String: String] = [:], token: String? = nil) -> AsyncStream<SseEvent> {
        guard let url = URL(string: urlString) else {
            return AsyncStream { continuation in
                continuation.yield(.error(ApiError.invalidURL))
                continuation.finish()
            }
        }
        return connect(url: url, headers: headers, token: token)
    }

    private func doConnect() {
        guard let url = currentURL, shouldReconnect else { return }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(Int.max)
        config.timeoutIntervalForResource = TimeInterval(Int.max)
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (key, value) in currentHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let lastEventId {
            request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-ID")
        }

        buffer = ""
        task = session?.dataTask(with: request)
        task?.resume()
    }

    func disconnect() {
        shouldReconnect = false
        isConnected = false
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        continuation?.finish()
        continuation = nil
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }

        if httpResponse.statusCode == 200 {
            isConnected = true
            reconnectDelay = 1.0
            continuation?.yield(.connected)
            onEvent?(.connected)
            completionHandler(.allow)
        } else if httpResponse.statusCode == 401 {
            continuation?.yield(.error(ApiError.unauthorized))
            completionHandler(.cancel)
        } else {
            continuation?.yield(.error(ApiError.serverError(httpResponse.statusCode, "SSE connection failed")))
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text
        processBuffer()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        isConnected = false

        if let error = error as? URLError, error.code == .cancelled {
            continuation?.yield(.disconnected)
            onEvent?(.disconnected)
            return
        }

        if let error {
            continuation?.yield(.error(error))
            onEvent?(.error(error))
        }

        if shouldReconnect {
            scheduleReconnect()
        } else {
            continuation?.yield(.disconnected)
            onEvent?(.disconnected)
        }
    }

    // MARK: - SSE Parsing

    private func processBuffer() {
        let lines = buffer.components(separatedBy: "\n")
        var processedUpTo = 0
        var currentEventId: String?
        var currentEvent: String?
        var currentData = ""

        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                if !currentData.isEmpty {
                    let data = currentData
                    let event = currentEvent
                    let id = currentEventId
                    continuation?.yield(.message(id: id, event: event, data: data))
                    onEvent?(.message(id: id, event: event, data: data))
                    if let id { lastEventId = id }
                }
                currentEventId = nil
                currentEvent = nil
                currentData = ""
                processedUpTo = index + 1
                continue
            }

            if line.hasPrefix(":") { continue }

            if line.hasPrefix("id:") {
                currentEventId = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("event:") {
                currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let value = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if currentData.isEmpty {
                    currentData = value
                } else {
                    currentData += "\n" + value
                }
            } else if line.hasPrefix("retry:") {
                let value = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if let ms = Int(value) {
                    reconnectDelay = Double(ms) / 1000.0
                }
            }
        }

        if processedUpTo > 0 {
            let remaining = lines.dropFirst(processedUpTo)
            buffer = remaining.joined(separator: "\n")
        }
    }

    // MARK: - Reconnect

    private func scheduleReconnect() {
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.reconnectDelay * 1_000_000_000))
            guard self.shouldReconnect else { return }
            self.reconnectDelay = min(self.reconnectDelay * 2, self.maxReconnectDelay)
            self.doConnect()
        }
    }
}
