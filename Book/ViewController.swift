//
//  ViewController.swift
//  Book
//
//  Created by Horace Ho on 20/10/2022.
//

import UIKit
import PDFKit

struct Book: Codable {
    var hash: String
    var name: String
    var path: URL
    var page: Int = 0
    var mode: Int = 0
    var point: CGPoint = CGPointZero // of PDFDestination
    var zoom: CGFloat = 1.0 // of PDFDestination
    var rect: CGRect = CGRectZero
    var auto: Bool = true
    var scale: CGFloat = 1.0
    var tofit: CGFloat = 1.0
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
            let index = doc.index(for: page)
            let mode = Int(pdf.displayMode.rawValue)
            let point = destination.point
            let zoom = destination.zoom
            let rect = pdf.convert(pdf.bounds, to:page)
            let auto = pdf.autoScales
            let scale = pdf.scaleFactor
            let tofit = pdf.scaleFactorForSizeToFit
            let name = url.lastPathComponent
            latest = String(format:"%02X", name.hashValue)
            if (index > 0) {
                if let first = books.firstIndex(where: { $0.hash == latest }) {
                    books[first].page = index
                    books[first].mode = mode
                    books[first].point = point
                    books[first].zoom = zoom
                    books[first].rect = rect
                    books[first].auto = auto
                    books[first].scale = scale
                    books[first].tofit = tofit
                } else {
                    books.append(Book(
                        hash: latest,
                        name: name,
                        path: url,
                        page: index,
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
        if let hash = UserDefaults.standard.string(forKey: "latest") {
            latest = hash
        }
        if let data = UserDefaults.standard.data(forKey: "history") {
            if let decoded = try? JSONDecoder().decode([Book].self, from: data) {
                books = decoded
            }
        }
        debugPrint("load \(latest)")
    }

    func book(url: URL) -> Book? {
        if let first = books.firstIndex(where: { $0.hash == url.hash() }) {
            return books[first]
        }
        return nil
    }

    func book() -> Book? {
        if let first = books.firstIndex(where: { $0.hash == latest }) {
            return books[first]
        }
        return nil
    }

    func rect() -> CGRect {
        if let index = books.firstIndex(where: { $0.hash == latest }) {
            return books[index].rect
        }
        return CGRectZero
    }
}

extension PDFView {
    func page() -> Int {
        if let doc = self.document,
           let page = self.currentPage {
            let index = doc.index(for: page)
            return index
        }
        return 0
    }
    func rect() -> CGRect {
        if let page = self.currentPage {
            return self.convert(self.bounds, to:page)
        } else {
            return CGRectZero
        }
    }
}

extension URL {
    func hash() -> String {
        return String(format:"%02X", self.lastPathComponent.hashValue)
    }
}

class ViewController: UIViewController {

    var history = History(books: [])
    var hiddenHomeBar: Bool = false
    var hiddenStatusBar: Bool = false
    weak var scheduler: Timer?

    @IBOutlet weak var pdfView: PDFView?

    @IBOutlet var infoButton: UIView!
    @IBOutlet var menuButton: UIView!
    @IBOutlet var prevButton: UIView!
    @IBOutlet var nextButton: UIView!

    @IBOutlet var configView: UIView! {
        didSet {
            configView.layer.cornerRadius = 8
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return hiddenHomeBar
    }

    override var prefersStatusBarHidden: Bool {
        return hiddenStatusBar
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        if let pdf = pdfView {
            if let doc = pdf.document {
                if let url = doc.documentURL {
                    print("resume \(url.lastPathComponent)")
                }
            } else {
                history.load()
                if let book = history.book() {
                    print("reload \(book.path.lastPathComponent)")
                    openUrl(url: book.path)
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoadUrl(notification:)),
            name: Notification.Name("loadUrl"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDocumentChanged(notification:)),
            name: .PDFViewDocumentChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePageChanged(notification:)),
            name: .PDFViewPageChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayBoxChanged(notification:)),
            name: .PDFViewDisplayBoxChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScaleChanged(notification:)),
            name: .PDFViewScaleChanged,
            object: nil
        )

        scheduler = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)

        if let pdf = pdfView {
            let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(sender:)))
            doubleTap.numberOfTapsRequired = 2
            pdf.addGestureRecognizer(doubleTap)

            let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(sender:)))
            singleTap.numberOfTapsRequired = 1
            singleTap.require(toFail: doubleTap)
            pdf.addGestureRecognizer(singleTap)

            doubleTap.delaysTouchesBegan = true
            singleTap.delaysTouchesBegan = true
        }
    }

    @objc func handleSingleTap(sender: AnyObject?) {
        pdfView?.goToNextPage(nil)
    }

    @objc func handleDoubleTap(sender: AnyObject?) {
        pdfView?.goToPreviousPage(nil)
    }

    @objc func handleDocumentChanged(notification: Notification) {
        if let pdf = pdfView,
           let doc = pdf.document,
           let url = doc.documentURL {
            debugPrint("handleDocumentChanged: \(url)")
        }
    }

    @objc func handlePageChanged(notification: Notification) {
        let page = pdfView?.page() ?? 0
        debugPrint("handlePageChanged \(page)")
        pdfView?.currentSelection = nil
        pdfView?.clearSelection()
        history.save(pdfView: pdfView)
    }

    @objc func handleDisplayBoxChanged(notification: Notification) {
        debugPrint("handleDisplayBoxChanged")
    }

    @objc func handleScaleChanged(notification: Notification) {
        debugPrint("handleScaleChanged")
        history.save(pdfView: pdfView)
    }

    @objc func handleTimer(sender: AnyObject?) {
        let page = pdfView?.page() ?? 0
        if page > 0 && pdfView?.rect() != CGRectZero && pdfView?.rect() != history.rect() {
            debugPrint("handleTimer")
            history.save(pdfView: pdfView)
        }
    }

    @objc func handleLoadUrl(notification: Notification) {
        debugPrint("openUrl")
        if let url = notification.userInfo?["url"] as? URL {
            openUrl(url: url)
        }
    }

    @objc func handlePanInScrollView(_ sender: UIGestureRecognizer) {
        debugPrint(sender)
    }

    @objc func handleActive() {
        print("handleActive")
        updateSettings()
    }

    @IBAction func tapInsideInfoButton() {
        debugPrintAll()
    }

    @IBAction func tapInsideMenuButton() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    @IBAction func tapInsidePrevButton() {
        print("tapInsidePrevButton")
        pdfView?.goToPreviousPage(nil)
    }

    @IBAction func tapInsideNextButton() {
        print("tapInsideNextButton")
        pdfView?.goToNextPage(nil)
    }

    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        print(location)
    }

    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        guard let gestureView = gesture.view else {
            return
        }

        gestureView.center = CGPoint(
            x: gestureView.center.x + translation.x,
            y: gestureView.center.y + translation.y
        )

        gesture.setTranslation(.zero, in: view)
    }

    func openUrl(url: URL) {
        if let pdf = pdfView {
            let document = PDFDocument(url: url)
            pdf.document = document

            history.load()
            if let book = history.book(url: url) {
                if let doc = pdf.document,
                   let page = doc.page(at: book.page) {
                    pdf.autoScales = book.auto
                    pdf.scaleFactor = book.scale
                    pdf.displayMode = PDFDisplayMode(rawValue: book.mode) ?? .singlePage
                    let destination = PDFDestination(page: page, at: book.point)
                    destination.zoom = book.zoom
                    pdf.go(to: destination)
                    pdf.go(to: book.rect, on: page)
                }
            } else {
                pdf.autoScales = true
                pdf.displayMode = .singlePage
            }
            pdf.pageShadowsEnabled = false
            pdf.displaysPageBreaks = false
        }

        if let color = UserDefaults.standard.object(forKey: "background") as? String? ?? ".white" {
            let toSet: UIColor = (color == ".clear") ? .clear : .white
            for view in pdfView?.subviews ?? [] {
                debugPrint("view \(view)")
//                let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanInScrollView(_:)))
//                panGestureRecognizer.cancelsTouchesInView = false
//                view.addGestureRecognizer(panGestureRecognizer)
//                view.backgroundColor = toSet
            }
            pdfView?.backgroundColor = toSet
        }
    }

    func updateSettings() {
        print("updateSettings")
        if UserDefaults.standard.bool(forKey: "reset") {
            UserDefaults.standard.set(false, forKey: "reset")
            UserDefaults.standard.set(".white", forKey: "background")
            UserDefaults.standard.set(false, forKey: "hiddenHomeBar")
            UserDefaults.standard.set(false, forKey: "hiddenStatusBar")
            UserDefaults.standard.set(false, forKey: "dimMenuButton")
            UserDefaults.standard.removeObject(forKey: "history")
            UserDefaults.standard.removeObject(forKey: "latest")
            UserDefaults.standard.synchronize()
            history.reset()
        }

        hiddenHomeBar = UserDefaults.standard.bool(forKey: "hiddenHomeBar")
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()

        hiddenStatusBar = UserDefaults.standard.bool(forKey: "hiddenStatusBar")
        UIView.animate(withDuration: 2.0, animations: {
            self.setNeedsStatusBarAppearanceUpdate()

            let alpha = UserDefaults.standard.bool(forKey: "dimMenuButton") ? 0.15 : 1.0
            self.infoButton.alpha = 0.05
            self.menuButton.alpha = alpha
        })
    }

    func debugPrintAll() {
        if let pdf = pdfView {
            debugPrint("isUsingPageViewController: \(pdf.isUsingPageViewController)")
            debugPrint("backgroundColor: \(pdf.backgroundColor)")
            debugPrint("displaysAsBook: \(pdf.displaysAsBook)")
            debugPrint("displaysPageBreaks: \(pdf.displaysPageBreaks)")
            debugPrint("displayDirection: \(pdf.displayDirection)")
            debugPrint("displayMode: \(pdf.displayMode)")
            debugPrint("displayBox: \(pdf.displayBox)")
            debugPrint("displaysRTL: \(pdf.displaysRTL)")
            debugPrint("scaleFactor: \(pdf.scaleFactor)")
            debugPrint("scaleFactorForSizeToFit: \(pdf.scaleFactorForSizeToFit)")
            debugPrint("autoScales: \(pdf.autoScales)")
            if let doc = pdf.document,
               let url = doc.documentURL {
                debugPrint("url: \(url)")
            }
            if let page = pdf.page(for: CGPointZero, nearest: true) {
                let rect = pdf.convert(pdf.bounds, to:page)
                debugPrint("bounds: \(pdf.bounds) converted: \(rect)")
            }
            debugPrint(history)
        }
    }
}
