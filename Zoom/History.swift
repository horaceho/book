//
//  History.swift
//  Zoom
//
//  Created by Horace Ho on 28/10/2022.
//

import UIKit
import PDFKit
import CryptoKit

extension String {
    var md5: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

extension URL {
    var name: String {
        let name = self.deletingPathExtension().lastPathComponent
        return name // .replacingOccurrences(of: "(-|~)([0-9]+)$", with: "", options: .regularExpression, range: nil)
    }
    var hash: String {
        return self.name.md5
    }
}

struct History: Codable {
    var books: [Book] = []
    var latest: String = ""

    mutating func reset() {
        books = []
        latest = ""
    }

    mutating func save(pdfView: PDFView?) {
        if let pdf = pdfView,
           let doc = pdf.document,
           let url = doc.documentURL,
           let page = pdf.currentPage,
           let destination = pdf.currentDestination {
            let count = doc.pageCount
            let index = doc.index(for: page)
            let mode = Int(pdf.displayMode.rawValue)
            let point = destination.point
            let zoom = destination.zoom
            let rect = pdf.convert(pdf.bounds, to:page)
            let auto = pdf.autoScales
            let scale = pdf.scaleFactor
            let tofit = pdf.scaleFactorForSizeToFit
            let name = url.name
            latest = url.hash
            if (index > 0) {
                if let first = books.firstIndex(where: { $0.code == latest }) {
                    books[first].index = index
                    books[first].mode = mode
                    books[first].point = point
                    books[first].zoom = zoom
                    books[first].rect = rect
                    books[first].auto = auto
                    books[first].scale = scale
                    books[first].tofit = tofit
                } else {
                    books.append(Book(
                        code: latest,
                        name: name,
                        path: url,
                        count: count,
                        index: index,
                        mode: mode,
                        point: point,
                        zoom: zoom,
                        rect: rect,
                        auto: auto,
                        scale: scale,
                        tofit: tofit
                    ))
                }

                if let data = try? JSONEncoder().encode(books) {
                    UserDefaults.standard.set(data, forKey: "history")
                }
                UserDefaults.standard.set(latest, forKey: "latest")
                UserDefaults.standard.synchronize()
                debugPrint("save \(latest)")
            } else {
                debugPrint("save \(latest) ignored")
            }
        }
    }

    mutating func load() {
        if let code = UserDefaults.standard.string(forKey: "latest") {
            latest = code
        }
        if let data = UserDefaults.standard.data(forKey: "history") {
            if let decoded = try? JSONDecoder().decode([Book].self, from: data) {
                books = decoded
            }
        }
        debugPrint("load \(latest)")
    }

    func book(url: URL) -> Book? {
        if let first = books.firstIndex(where: { $0.code == url.hash }) {
            return books[first]
        }
        return nil
    }

    func book() -> Book? {
        if let first = books.firstIndex(where: { $0.code == latest }) {
            return books[first]
        }
        return nil
    }

    func rect() -> CGRect {
        if let index = books.firstIndex(where: { $0.code == latest }) {
            return books[index].rect
        }
        return CGRectZero
    }
}
