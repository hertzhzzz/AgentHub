import Foundation

/// Tolerant parser for the small YAML-frontmatter subset used by rulesync files:
/// scalars, folded (`>`, `>-`) and literal (`|`, `|-`) blocks, and simple lists.
/// Nested maps are skipped.
struct Frontmatter: Equatable {
    enum Value: Equatable {
        case scalar(String)
        case list([String])
    }

    var fields: [String: Value] = [:]
    var body: String = ""

    func string(_ key: String) -> String? {
        if case .scalar(let s)? = fields[key] { return s }
        return nil
    }

    func list(_ key: String) -> [String]? {
        switch fields[key] {
        case .list(let l)?: return l
        case .scalar(let s)?: return s.isEmpty ? [] : [s]
        case nil: return nil
        }
    }

    static func parse(_ text: String) -> Frontmatter {
        var lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return Frontmatter(fields: [:], body: lines.joined(separator: "\n"))
        }
        lines.removeFirst()
        guard let end = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            return Frontmatter(fields: [:], body: lines.joined(separator: "\n"))
        }
        let yaml = Array(lines[..<end])
        let body = lines[(end + 1)...].joined(separator: "\n")
        return Frontmatter(fields: parseYAML(yaml), body: body)
    }

    private static func indent(_ line: String) -> Int {
        line.prefix(while: { $0 == " " || $0 == "\t" }).count
    }

    private static func unquote(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespaces)
        if t.count >= 2, let f = t.first, let l = t.last, (f == "'" && l == "'") || (f == "\"" && l == "\"") {
            return String(t.dropFirst().dropLast())
        }
        return t
    }

    private static func parseYAML(_ lines: [String]) -> [String: Value] {
        var result: [String: Value] = [:]
        var i = 0
        while i < lines.count {
            let line = lines[i]
            i += 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || indent(line) > 0 { continue }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let rest = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)

            // Collect the continuation lines: indented, blank, or top-level "- " items.
            var block: [String] = []
            while i < lines.count {
                let next = lines[i]
                if next.trimmingCharacters(in: .whitespaces).isEmpty || indent(next) > 0
                    || (rest.isEmpty && next.hasPrefix("- ")) {
                    block.append(next)
                    i += 1
                } else { break }
            }
            while let last = block.last, last.trimmingCharacters(in: .whitespaces).isEmpty { block.removeLast() }

            if let marker = rest.first, marker == ">" || marker == "|" {
                let folded = marker == ">"
                let parts = block.map { $0.trimmingCharacters(in: .whitespaces) }
                var text: String
                if folded {
                    text = parts.joined(separator: " ").replacingOccurrences(of: "  ", with: " ")
                } else {
                    text = parts.joined(separator: "\n")
                }
                result[key] = .scalar(text.trimmingCharacters(in: .whitespacesAndNewlines))
            } else if rest.isEmpty {
                let items = block.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if !items.isEmpty, items.allSatisfy({ $0.hasPrefix("- ") || $0 == "-" }) {
                    result[key] = .list(items.map { unquote(String($0.dropFirst())) })
                } else if items.isEmpty {
                    result[key] = .scalar("")
                }
                // Nested map: skipped.
            } else if rest.hasPrefix("["), rest.hasSuffix("]") {
                let inner = rest.dropFirst().dropLast()
                result[key] = .list(inner.split(separator: ",").map { unquote(String($0)) }.filter { !$0.isEmpty })
            } else {
                result[key] = .scalar(unquote(rest))
            }
        }
        return result
    }
}
