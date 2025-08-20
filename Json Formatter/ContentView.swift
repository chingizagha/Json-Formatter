//
//  ContentView.swift
//  Json Formatter
//
//  Created by Chingiz on 20.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputText = ""
    @State private var formattedText = ""
    @State private var errorMessage = ""
    @State private var indentationType: IndentationType = .spaces4
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showingFilePicker = false
    @State private var compareText = ""
    @State private var diffResult = ""
    @State private var sortKeys = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum IndentationType: String, CaseIterable {
        case spaces2 = "2 Spaces"
        case spaces4 = "4 Spaces"
        case tabs = "Tabs"
        
        var value: String {
            switch self {
            case .spaces2: return "  "
            case .spaces4: return "    "
            case .tabs: return "\t"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Format JSON") {
                    formatJSON()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clean & Format") {
                    cleanAndFormatJSON()
                }
                .buttonStyle(.bordered)
                .help("Handles Swift interpolation and escaped JSON")
                
                Button("Validate") {
                    validateJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Clear") {
                    clearAll()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                // Settings
                Menu("Settings") {
                    Picker("Indentation", selection: $indentationType) {
                        ForEach(IndentationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Toggle("Sort Keys", isOn: $sortKeys)
                    
                    Divider()
                    
                    Button("Import JSON File") {
                        showingFilePicker = true
                    }
                    
                    Button("Export JSON") {
                        exportJSON()
                    }
                    .disabled(formattedText.isEmpty)
                    
                    Button("Copy to Clipboard") {
                        copyToClipboard()
                    }
                    .disabled(formattedText.isEmpty)
                }
                
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Search Bar
            if !formattedText.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search keys or values...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            // Tab View
            TabView(selection: $selectedTab) {
                // Main Editor Tab
                mainEditorView
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Formatter")
                    }
                    .tag(0)
                
                // Compare Tab
                compareView
                    .tabItem {
                        Image(systemName: "doc.on.doc")
                        Text("Compare")
                    }
                    .tag(1)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private var mainEditorView: some View {
        HSplitView {
            // Input Side
            VStack(alignment: .leading, spacing: 8) {
                Text("Input JSON")
                    .font(.headline)
                    .padding(.horizontal)
                
                ZStack {
                    if inputText.isEmpty {
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Paste your JSON here")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Supports regular JSON and Swift-interpolated strings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                }
                .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
            
            // Output Side
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Formatted JSON")
                        .font(.headline)
                    Spacer()
                    if !errorMessage.isEmpty {
                        if errorMessage.contains("✅") {
                            Text("✅ Valid JSON")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Text("❌ Invalid JSON")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty && !errorMessage.contains("✅") {
                    ScrollView {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .frame(maxHeight: 120)
                }
                
                ZStack {
                    if formattedText.isEmpty && errorMessage.isEmpty {
                        VStack {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Formatted JSON will appear here")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    ScrollView {
                        SyntaxHighlightedText(
                            text: highlightSearchMatches(formattedText),
                            isDarkMode: isDarkMode
                        )
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
    }
    
    private var compareView: some View {
        VStack(spacing: 12) {
            Text("JSON Comparison")
                .font(.headline)
                .padding(.top)
            
            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON 1")
                        .font(.subheadline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON 2")
                        .font(.subheadline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $compareText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                }
            }
            .frame(maxHeight: 300)
            
            Button("Compare JSONs") {
                compareJSONs()
            }
            .buttonStyle(.borderedProminent)
            
            if !diffResult.isEmpty {
                ScrollView {
                    Text(diffResult)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
    }
    
    // MARK: - Functions
    
    private func preprocessJSON(_ input: String) -> String {
        var processed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Step 1: Clean up escaped quotes first
        processed = processed.replacingOccurrences(of: "\\\"", with: "\"")
        
        // Step 2: Handle Swift string interpolation patterns more precisely
        // Pattern: \(anything) -> "PLACEHOLDER"
        let interpolationPattern = "\\\\\\([^)]+\\)"
        processed = processed.replacingOccurrences(of: interpolationPattern, with: "\"PLACEHOLDER\"", options: .regularExpression)
        
        // Step 3: Handle specific patterns that might remain
        // Handle cases like \(variable ?? "default")
        let nilCoalescingPattern = "\\\\\\([^)]*\\s*\\?\\?\\s*\"[^\"]*\"[^)]*\\)"
        processed = processed.replacingOccurrences(of: nilCoalescingPattern, with: "[]", options: .regularExpression)
        
        // Handle cases like \(variable ?? "")
        let emptyStringPattern = "\\\\\\([^)]*\\s*\\?\\?\\s*\"\"[^)]*\\)"
        processed = processed.replacingOccurrences(of: emptyStringPattern, with: "\"\"", options: .regularExpression)
        
        // Step 4: Clean up any remaining Swift syntax
        // Remove any remaining \( and ) that might be left
        processed = processed.replacingOccurrences(of: "\\\\\\(", with: "\"")
        processed = processed.replacingOccurrences(of: "\\)", with: "\"")
        
        // Step 5: Fix common JSON formatting issues
        // Fix cases where we might have created ""PLACEHOLDER""
        processed = processed.replacingOccurrences(of: "\"\"PLACEHOLDER\"\"", with: "\"PLACEHOLDER\"")
        processed = processed.replacingOccurrences(of: "\"\"\"", with: "\"")
        
        // Fix spacing around colons
        processed = processed.replacingOccurrences(of: "\"\\s*:", with: "\":")
        processed = processed.replacingOccurrences(of: ":\\s*\"", with: ": \"")
        
        // Step 6: Handle any remaining syntax issues
        // Fix double quotes that might be created
        processed = processed.replacingOccurrences(of: "\"\"", with: "\"")
        
        // Clean up multiple spaces
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Step 7: Final cleanup for common issues
        processed = processed.replacingOccurrences(of: " ?? ", with: ": ")
        
        return processed
    }
    
    private func cleanAndFormatJSON() {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter JSON text to clean and format"
            return
        }
        
        // Try a more sophisticated cleaning approach
        let cleaned = cleanSwiftInterpolatedJSON(inputText)
        
        // Try to parse and format the cleaned JSON
        do {
            let jsonData = cleaned.data(using: .utf8)!
            var jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            
            if sortKeys {
                jsonObject = sortJSONKeys(jsonObject)
            }
            
            let formattedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys]
            )
            
            var formatted = String(data: formattedData, encoding: .utf8) ?? ""
            
            // Apply custom indentation
            if indentationType != .spaces4 {
                formatted = applyCustomIndentation(formatted)
            }
            
            formattedText = formatted
            errorMessage = ""
            
            // Show the cleaned input in the input field for reference
            inputText = cleaned
            
        } catch {
            // If it still fails, show both the cleaned version and error
            formattedText = cleaned
            errorMessage = "Cleaned JSON but still invalid: \(error.localizedDescription)\n\nCleaned version shown in output. You may need to manually fix remaining issues."
        }
    }
    
    private func cleanSwiftInterpolatedJSON(_ input: String) -> String {
        var result = input
        
        // Remove escaped quotes first
        result = result.replacingOccurrences(of: "\\\"", with: "\"")
        
        // More precise pattern matching for Swift interpolation
        // Handle patterns like \(**self**.property.subproperty)
        let complexInterpolationPattern = "\\\\\\([^)]*\\)"
        let matches = result.ranges(of: complexInterpolationPattern, options: .regularExpression)
        
        // Replace from end to start to preserve indices
        for range in matches.reversed() {
            let interpolationContent = String(result[range])
            
            // Check if it's a nil coalescing expression
            if interpolationContent.contains("??") {
                if interpolationContent.contains("\"[]\"") {
                    result.replaceSubrange(range, with: "[]")
                } else if interpolationContent.contains("\"\"") {
                    result.replaceSubrange(range, with: "\"\"")
                } else {
                    result.replaceSubrange(range, with: "\"PLACEHOLDER\"")
                }
            } else {
                result.replaceSubrange(range, with: "\"PLACEHOLDER\"")
            }
        }
        
        // Clean up any remaining issues
        result = result.replacingOccurrences(of: "\"\"PLACEHOLDER\"\"", with: "\"PLACEHOLDER\"")
        result = result.replacingOccurrences(of: "\"\"\"", with: "\"")
        result = result.replacingOccurrences(of: "\"\" ", with: "\" ")
        
        // Fix JSON formatting
        result = result.replacingOccurrences(of: "\" :", with: "\":")
        result = result.replacingOccurrences(of: ": \"", with: ": \"")
        
        return result
    }
    
    private func formatJSON() {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter JSON text to format"
            return
        }
        
        do {
            let jsonData = inputText.data(using: .utf8)!
            var jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            
            if sortKeys {
                jsonObject = sortJSONKeys(jsonObject)
            }
            
            let formattedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys]
            )
            
            var formatted = String(data: formattedData, encoding: .utf8) ?? ""
            
            // Apply custom indentation
            if indentationType != .spaces4 {
                formatted = applyCustomIndentation(formatted)
            }
            
            formattedText = formatted
            errorMessage = ""
        } catch {
            errorMessage = "Invalid JSON: \(error.localizedDescription)\n\nTip: If your JSON contains Swift interpolation or escaped quotes, try the 'Clean & Format' button."
            formattedText = ""
        }
    }
    
    private func validateJSON() {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter JSON text to validate"
            return
        }
        
        do {
            let jsonData = inputText.data(using: .utf8)!
            _ = try JSONSerialization.jsonObject(with: jsonData)
            errorMessage = "✅ Valid JSON"
            
            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if errorMessage == "✅ Valid JSON" {
                    errorMessage = ""
                }
            }
        } catch {
            errorMessage = "Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func clearAll() {
        inputText = ""
        formattedText = ""
        errorMessage = ""
        searchText = ""
        compareText = ""
        diffResult = ""
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(formattedText, forType: .string)
    }
    
    private func exportJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "formatted.json"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try formattedText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                inputText = content
                formatJSON()
            } catch {
                errorMessage = "Error reading file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Error importing file: \(error.localizedDescription)"
        }
    }
    
    private func applyCustomIndentation(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        
        for line in lines {
            let leadingSpaces = line.prefix(while: { $0 == " " }).count
            let indentLevel = leadingSpaces / 4 // Assuming original is 4-space indented
            let newIndent = String(repeating: indentationType.value, count: indentLevel)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if !trimmed.isEmpty {
                result.append(newIndent + trimmed)
            } else {
                result.append("")
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private func sortJSONKeys(_ object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var sortedDict: [String: Any] = [:]
            for (key, value) in dict {
                sortedDict[key] = sortJSONKeys(value)
            }
            return sortedDict
        } else if let array = object as? [Any] {
            return array.map(sortJSONKeys)
        }
        return object
    }
    
    private func highlightSearchMatches(_ text: String) -> String {
        guard !searchText.isEmpty else { return text }
        
        let highlightedText = text.replacingOccurrences(
            of: searchText,
            with: "🔍\(searchText)🔍",
            options: .caseInsensitive
        )
        
        return highlightedText
    }
    
    private func compareJSONs() {
        guard !inputText.isEmpty && !compareText.isEmpty else {
            diffResult = "Please provide both JSON texts to compare"
            return
        }
        
        do {
            let json1Data = inputText.data(using: .utf8)!
            let json2Data = compareText.data(using: .utf8)!
            
            let json1 = try JSONSerialization.jsonObject(with: json1Data)
            let json2 = try JSONSerialization.jsonObject(with: json2Data)
            
            let differences = findDifferences(json1, json2, path: "")
            
            if differences.isEmpty {
                diffResult = "✅ JSONs are identical"
            } else {
                diffResult = "Differences found:\n\n" + differences.joined(separator: "\n")
            }
            
        } catch {
            diffResult = "Error comparing JSONs: \(error.localizedDescription)"
        }
    }
    
    private func findDifferences(_ obj1: Any, _ obj2: Any, path: String) -> [String] {
        var differences: [String] = []
        
        if let dict1 = obj1 as? [String: Any], let dict2 = obj2 as? [String: Any] {
            let allKeys = Set(dict1.keys).union(Set(dict2.keys))
            
            for key in allKeys.sorted() {
                let currentPath = path.isEmpty ? key : "\(path).\(key)"
                
                if dict1[key] == nil {
                    differences.append("➕ Added: \(currentPath) = \(dict2[key] ?? "null")")
                } else if dict2[key] == nil {
                    differences.append("➖ Removed: \(currentPath) = \(dict1[key] ?? "null")")
                } else {
                    differences.append(contentsOf: findDifferences(dict1[key]!, dict2[key]!, path: currentPath))
                }
            }
        } else if let arr1 = obj1 as? [Any], let arr2 = obj2 as? [Any] {
            if arr1.count != arr2.count {
                differences.append("🔢 Array length changed at \(path): \(arr1.count) -> \(arr2.count)")
            }
            
            for i in 0..<min(arr1.count, arr2.count) {
                let currentPath = "\(path)[\(i)]"
                differences.append(contentsOf: findDifferences(arr1[i], arr2[i], path: currentPath))
            }
        } else {
            let obj1Str = String(describing: obj1)
            let obj2Str = String(describing: obj2)
            
            if obj1Str != obj2Str {
                differences.append("🔄 Changed: \(path) = \(obj1Str) -> \(obj2Str)")
            }
        }
        
        return differences
    }
}

// MARK: - Extensions
extension String {
    func ranges(of searchString: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex
        
        while let range = self.range(of: searchString, options: options, range: searchStartIndex..<self.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}

// MARK: - Syntax Highlighting Component
struct SyntaxHighlightedText: View {
    let text: String
    let isDarkMode: Bool
    
    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(isDarkMode ? .white : .black)
            .textSelection(.enabled)
    }
}
