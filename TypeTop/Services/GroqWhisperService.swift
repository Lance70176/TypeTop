import Foundation

/// Groq Whisper API 服務
struct GroqWhisperService: STTService {

    func transcribe(audioData: Data, language: String?, prompt: String?) async throws -> TranscriptionResult {
        guard !audioData.isEmpty else { throw STTError.emptyAudio }

        let scope = APIAccountStore.scope(stt: .groq)
        let store = APIAccountStore.shared

        guard var account = await MainActor.run(body: { store.activeAccount(scope) }) else {
            throw STTError.noAPIKey
        }

        // 達額度（429）時自動輪替到下一組帳號重試，全部試過才放棄
        var triedIDs: Set<UUID> = []
        while true {
            do {
                return try await attempt(audioData: audioData, language: language, prompt: prompt, account: account, scope: scope)
            } catch STTError.rateLimited {
                triedIDs.insert(account.id)
                let next = await MainActor.run { store.switchToNext(scope) }
                guard let next, !triedIDs.contains(next.id) else {
                    throw STTError.rateLimited
                }
                account = next
            }
        }
    }

    private func attempt(audioData: Data, language: String?, prompt: String?, account: APIAccount, scope: String) async throws -> TranscriptionResult {
        let apiKey = account.key
        let usageKey = "\(scope)#\(account.id.uuidString)"

        let startTime = Date()

        let url = URL(string: APIProvider.groq.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 音訊檔案
        body.appendMultipart(boundary: boundary, name: "file", filename: "audio.wav", mimeType: "audio/wav", data: audioData)

        // 模型
        body.appendMultipart(boundary: boundary, name: "model", value: APIProvider.groq.modelName)

        // 語言
        if let language = language {
            body.appendMultipart(boundary: boundary, name: "language", value: language)
        }

        // 提示文字
        if let prompt = prompt {
            body.appendMultipart(boundary: boundary, name: "prompt", value: prompt)
        }

        // 回應格式
        body.appendMultipart(boundary: boundary, name: "response_format", value: "verbose_json")

        // 溫度（降低以提高準確度）
        body.appendMultipart(boundary: boundary, name: "temperature", value: "0.0")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw STTError.invalidResponse
        }

        UsageTracker.shared.updateGroqLimits(key: usageKey, response: httpResponse)

        guard httpResponse.statusCode != 429 else {
            throw STTError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? L("error.unknown")
            throw STTError.apiError("HTTP \(httpResponse.statusCode): \(errorMsg)")
        }

        UsageTracker.shared.record(usageKey)

        let duration = Date().timeIntervalSince(startTime)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw STTError.invalidResponse
        }

        let detectedLanguage = json["language"] as? String

        return TranscriptionResult(
            rawText: text,
            provider: .groq,
            duration: duration,
            detectedLanguage: detectedLanguage
        )
    }
}

// MARK: - Multipart Form Data Helper

extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        let field = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n"
        append(field.data(using: .utf8)!)
    }

    mutating func appendMultipart(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        var header = "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        append(header.data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
