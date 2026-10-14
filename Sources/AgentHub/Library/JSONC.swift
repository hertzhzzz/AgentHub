import Foundation

enum JSONC {
    /// Removes `//` and `/* */` comments that are outside string literals.
    static func stripComments(_ input: String) -> String {
        var out = String.UnicodeScalarView()
        let s = Array(input.unicodeScalars)
        var i = 0
        var inString = false
        while i < s.count {
            let c = s[i]
            if inString {
                out.append(c)
                if c == "\\", i + 1 < s.count { out.append(s[i + 1]); i += 2; continue }
                if c == "\"" { inString = false }
                i += 1
            } else if c == "\"" {
                inString = true; out.append(c); i += 1
            } else if c == "/", i + 1 < s.count, s[i + 1] == "/" {
                while i < s.count, s[i] != "\n" { i += 1 }
            } else if c == "/", i + 1 < s.count, s[i + 1] == "*" {
                i += 2
                while i + 1 < s.count, !(s[i] == "*" && s[i + 1] == "/") { i += 1 }
                i += 2
            } else {
                out.append(c); i += 1
            }
        }
        return String(out)
    }

    /// Parses JSONC, also tolerating trailing commas. Returns nil when unreadable.
    static func parse(_ data: Data) -> Any? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        var cleaned = stripComments(text)
        cleaned = cleaned.replacingOccurrences(of: ",(\\s*[}\\]])", with: "$1", options: .regularExpression)
        guard let d = cleaned.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: d)
    }
}
