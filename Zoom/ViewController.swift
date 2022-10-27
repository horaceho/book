//
//  ViewController.swift
//  Book
//
//  Created by Horace Ho on 20/10/2022.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

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

class ViewController: UIViewController, UIDocumentPickerDelegate {

    var history = History(books: [])
    var hiddenHomeBar: Bool = false
    var hiddenStatusBar: Bool = false
    weak var scheduler: Timer?

    @IBOutlet weak var pdfView: PDFView?

    @IBOutlet var bookButton: UIView!
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
                    print("resume \(url.name)")
                }
            } else {
                history.load()
                if let book = history.book() {
                    print("latest \(history.latest)")
                    if let url = book.path, url.startAccessingSecurityScopedResource() {
                        print("reload \(url.name)")
                        defer  {
                            url.stopAccessingSecurityScopedResource()
                        }
                        NotificationCenter.default.post(name: NSNotification.Name("LoadUrl"), object: nil, userInfo: [
                            "url": url
                        ])
                    }
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
            name: Notification.Name("LoadUrl"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTurnPage(notification:)),
            name: Notification.Name("TurnPage"),
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
        debugPrint("handleLoadUrl")
        if let url = notification.userInfo?["url"] as? URL {
            openUrl(url: url)
        }
    }

    @objc func handleTurnPage(notification: Notification) {
        debugPrint("handleTurnPage")
        if let index = notification.userInfo?["index"] as? Int {
            if let pdf = pdfView,
               let doc = pdf.document,
               let page = doc.page(at: index) {
                    pdf.go(to: page)
            }
        }
    }

    @objc func handlePanInScrollView(_ sender: UIGestureRecognizer) {
        debugPrint(sender)
    }

    @objc func handleActive() {
        print("handleActive")
        updateSettings()
    }

    @IBAction func tapInsideBookButton() {
        let fileController = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf
        ])
        fileController.allowsMultipleSelection = false
        fileController.delegate = self
        present(fileController, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first, url.startAccessingSecurityScopedResource() {
            defer  {
                url.stopAccessingSecurityScopedResource()
            }
            NotificationCenter.default.post(name: NSNotification.Name("LoadUrl"), object: nil, userInfo: [
                "url": url
            ])
        }
    }

    @IBAction func tapInsideMenuButton() {
        //
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
                   let page = doc.page(at: book.index) {
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
//                let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanInScrollView(_:)))
//                panGestureRecognizer.cancelsTouchesInView = false
//                view.addGestureRecognizer(panGestureRecognizer)
                view.backgroundColor = toSet
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
            UserDefaults.standard.set(false, forKey: "dimMenuIcons")
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

            let alpha = UserDefaults.standard.bool(forKey: "dimMenuIcons") ? 0.1 : 1.0
            self.bookButton.alpha = alpha
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
